import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dependencies.dart';
import '../data/services/database/library_folder.dart';
import '../data/services/database/track.dart';

final analysisProgressProvider = StreamProvider((ref) async* {
  final library = await ref.watch(libraryRepositoryProvider.future);
  yield* library.watchAnalysisProgress();
});

final analyzingProvider = Provider(
  (ref) => ref.watch(analysisProgressProvider).value != null,
);

final libraryFoldersProvider = FutureProvider((ref) async {
  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.loadFolders();
});

// reloads when analysis starts and ends and when the scan finishes
final libraryTracksProvider = FutureProvider((ref) async {
  ref.watch(analyzingProvider);
  ref.watch(libraryRefreshProvider);
  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.loadTracks();
});

final tracksProvider = Provider(
  (ref) => ref.watch(libraryTracksProvider).value ?? const <Track>[],
);

final libraryProvider = NotifierProvider(LibraryNotifier.new);

class LibraryNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addFolder() async {
    final path = await getDirectoryPath();
    if (path == null) return;

    final library = await ref.read(libraryRepositoryProvider.future);
    library.addFolder(path);
    ref.invalidate(libraryFoldersProvider);
    await library.refresh();
    ref.invalidate(libraryTracksProvider);
  }

  Future<void> removeFolder(LibraryFolder folder) async {
    final library = await ref.read(libraryRepositoryProvider.future);
    library.removeFolder(folder);
    ref.invalidate(libraryFoldersProvider);
    await library.refresh();
    ref.invalidate(libraryTracksProvider);
  }
}
