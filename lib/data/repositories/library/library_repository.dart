import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:path/path.dart' as p;

import '../../../models/analysis_progress.dart';
import '../../../models/search_result.dart';
import '../../services/audio_decoder.dart';
import '../../services/database/library_database_service.dart';
import '../../services/database/library_folder.dart';
import '../../services/database/moment.dart';
import '../../services/database/track.dart';
import '../../services/sonic_embed.dart';

class LibraryRepository {
  static const _audioExtensions = {
    '.mp3',
    '.flac',
    '.m4a',
    '.ogg',
    '.opus',
    '.wav',
  };

  final LibraryDatabaseService _database;
  final AudioDecoder _decoder;
  final SonicEmbed _sonicEmbed;

  final _analysisProgress = StreamController<AnalysisProgress?>.broadcast();
  var _refreshing = false;
  var _refreshAgain = false;
  _Moments? _moments;

  LibraryRepository({
    required this._database,
    required this._decoder,
    required this._sonicEmbed,
  });

  Stream<AnalysisProgress?> watchAnalysisProgress() => _analysisProgress.stream;

  List<LibraryFolder> loadFolders() => _database.loadFolders();

  void addFolder(String path) {
    _database.saveFolder(LibraryFolder(path: p.normalize(path)));
  }

  void removeFolder(LibraryFolder folder) => _database.removeFolder(folder.id);

  List<Track> loadTracks() => _database.loadTracks();

  Future<void> refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }

    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _sync();
        await _embedTracks();
      } while (_refreshAgain);
    } finally {
      _refreshing = false;
      _analysisProgress.add(null);
    }
  }

  Future<Float32List> embedQuery(String query) => _sonicEmbed.embedQuery(query);

  List<SearchResult> searchText(List<double> query) {
    final moments = _loadMoments();
    if (moments.trackIds.isEmpty) return const [];
    return _bestMoments(moments, _Moments.score(moments.originals, query));
  }

  _Moments _loadMoments() =>
      _moments ??= _Moments.load(_database.loadAllMoments());

  List<SearchResult> _bestMoments(_Moments moments, List<double> scores) {
    final bestRowOf = <int, int>{};
    for (var row = 0; row < scores.length; row++) {
      final trackId = moments.trackIds[row];
      final best = bestRowOf[trackId];
      if (best != null && scores[best] >= scores[row]) continue;
      bestRowOf[trackId] = row;
    }

    final results = <SearchResult>[];
    final tracks = _database.loadTracksById(bestRowOf.keys.toList());
    for (final track in tracks) {
      if (track == null) continue;
      final row = bestRowOf[track.id]!;
      final start = Duration(seconds: moments.starts[row]);
      results.add(SearchResult(track, start, scores[row]));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  Future<void> _sync() async {
    final tracksByPath = {
      for (final track in _database.loadTracks()) track.path: track,
    };

    final changed = <Track>[];
    final found = <String>{};
    for (final folder in _database.loadFolders()) {
      final directory = Directory(folder.path);
      final entities = directory.list(recursive: true, followLinks: false);
      await for (final entity in entities) {
        if (entity is! File) continue;
        final file = File(p.normalize(entity.path));
        final extension = p.extension(file.path).toLowerCase();
        if (!_audioExtensions.contains(extension)) continue;

        found.add(file.path);
        final stat = await file.stat();
        final existing = tracksByPath[file.path];
        if (existing != null && !_hasChanged(existing, stat)) continue;
        changed.add(_readTrack(file, stat, existing));
      }
    }

    final removed = <int>[];
    for (final track in tracksByPath.values) {
      if (found.contains(track.path)) continue;
      removed.add(track.id);
    }

    if (changed.isEmpty && removed.isEmpty) return;

    _database.saveTracks(changed);
    _database.removeTracks(removed);
    _database.removeMoments([
      ...removed,
      for (final track in changed)
        if (track.embedding == null) track.id,
    ]);
    _moments = null;
  }

  Future<void> _embedTracks() async {
    final tracks = _database.loadTracksWithoutEmbedding();
    for (var idx = 0; idx < tracks.length; idx++) {
      _analysisProgress.add(AnalysisProgress(idx, tracks.length));
      final track = tracks[idx];
      final windows = await _embedWindows(track);
      if (windows == null) continue;

      track.embedding = Matrix.fromList(windows).mean().normalize().toList();
      _database.saveTrack(track);
      _database.removeMoments([track.id]);
      _database.saveMoments([
        for (var window = 0; window < windows.length; window++)
          Moment(
            trackId: track.id,
            startSeconds: window * SonicEmbed.windowSeconds,
            embedding: windows[window],
          ),
      ]);
      _moments = null;
    }
  }

  Future<List<Float32List>?> _embedWindows(Track track) async {
    try {
      final samples = await _decoder.decode(track.path);
      return await _sonicEmbed.embedWindows(samples);
    } catch (_) {
      return null;
    }
  }

  bool _hasChanged(Track track, FileStat stat) {
    if (track.size != stat.size) return true;
    return track.modified.millisecondsSinceEpoch !=
        stat.modified.millisecondsSinceEpoch;
  }

  Track _readTrack(File file, FileStat stat, Track? existing) {
    final metadata = _readMetadata(file);
    final track = Track(
      id: existing?.id ?? 0,
      path: file.path,
      size: stat.size,
      modified: stat.modified,
      title: metadata?.title ?? p.basenameWithoutExtension(file.path),
      artist: metadata?.artist,
      album: metadata?.album,
      durationMilliseconds: metadata?.duration?.inMilliseconds,
      genres: _splitGenres(metadata?.genres ?? const []),
    );

    // a retag changes the file but not the audio, so the same length keeps it
    final duration = track.durationMilliseconds;
    if (duration != null && duration == existing?.durationMilliseconds) {
      track.embedding = existing?.embedding;
    }
    return track;
  }

  // id3 separates genres with nulls, and m4a genres arrive with raw atom headers
  static List<String> _splitGenres(List<String> tags) {
    final genres = <String>[];
    for (final tag in tags) {
      for (final part in tag.split(RegExp(r'[\x00-\x1f]'))) {
        final genre = part.trim();
        if (genre.isEmpty || genre == 'data') continue;
        genres.add(genre);
      }
    }
    return genres;
  }

  AudioMetadata? _readMetadata(File file) {
    try {
      return readMetadata(file);
    } catch (_) {
      return null;
    }
  }
}

class _Moments {
  final List<int> trackIds;
  final List<int> starts;
  final Matrix originals;

  _Moments(this.trackIds, this.starts, this.originals);

  static _Moments load(List<Moment> moments) {
    if (moments.isEmpty) return _Moments(const [], const [], Matrix.empty());

    return _Moments(
      [for (final moment in moments) moment.trackId],
      [for (final moment in moments) moment.startSeconds],
      Matrix.fromList([for (final moment in moments) moment.embedding]),
    );
  }

  // rows are unit length, so a dot product is the cosine similarity
  static List<double> score(Matrix windows, List<double> query) {
    final column = windows * Matrix.column(query);
    return column.getColumn(0).toList();
  }
}
