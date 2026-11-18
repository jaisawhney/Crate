import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../domain/library_notifier.dart';

final libraryLengthProvider = Provider((ref) {
  var length = Duration.zero;
  for (final track in ref.watch(libraryTracksProvider)) {
    length += track.duration ?? Duration.zero;
  }
  return length;
});

final folderSongCountsProvider = Provider((ref) {
  final folders = ref.watch(libraryFoldersProvider);
  final tracks = ref.watch(libraryTracksProvider);
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
