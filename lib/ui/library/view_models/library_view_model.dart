import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../data/services/database/track.dart';
import '../../../domain/library_notifier.dart';

final songSearchProvider = NotifierProvider(SongSearch.new);

class SongSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String text) => state = fold(text.trim());

  // so "beyonce" finds "Beyoncé"
  static String fold(String text) => removeDiacritics(text.toLowerCase());
}

final foundTracksProvider = Provider((ref) {
  final search = ref.watch(songSearchProvider);
  final tracks = ref.watch(tracksProvider);
  if (search.isEmpty) return tracks;

  final found = <Track>[];
  for (final track in tracks) {
    final fields = [track.title, track.artist ?? '', ...track.genres];
    if (fields.any((field) => SongSearch.fold(field).contains(search))) {
      found.add(track);
    }
  }
  return found;
});

final libraryLengthProvider = Provider((ref) {
  var length = Duration.zero;
  for (final track in ref.watch(tracksProvider)) {
    length += track.duration ?? Duration.zero;
  }
  return length;
});

final folderSongCountsProvider = Provider((ref) {
  final folders = ref.watch(libraryFoldersProvider).value ?? const [];
  final tracks = ref.watch(tracksProvider);
  final counts = <int, int>{};
  for (final folder in folders) {
    var count = 0;
    for (final track in tracks) {
      if (p.isWithin(folder.path, track.path)) count++;
    }
    counts[folder.id] = count;
  }
  return counts;
});
