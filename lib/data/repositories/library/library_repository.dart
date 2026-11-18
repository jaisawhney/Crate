import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;

import '../../services/database/library_database_service.dart';
import '../../services/database/library_folder.dart';
import '../../services/database/track.dart';

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

  LibraryRepository({required this._database});

  List<LibraryFolder> loadFolders() => _database.loadFolders();

  void addFolder(String path) {
    _database.saveFolder(LibraryFolder(path: p.normalize(path)));
  }

  void removeFolder(LibraryFolder folder) => _database.removeFolder(folder.id);

  List<Track> loadTracks() => _database.loadTracks();

  Future<void> refresh() => _sync();

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
  }

  bool _hasChanged(Track track, FileStat stat) {
    if (track.size != stat.size) return true;
    return track.modified.millisecondsSinceEpoch !=
        stat.modified.millisecondsSinceEpoch;
  }

  Track _readTrack(File file, FileStat stat, Track? existing) {
    final metadata = _readMetadata(file);
    return Track(
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
