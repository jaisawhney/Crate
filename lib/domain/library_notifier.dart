import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dependencies.dart';
import '../data/services/database/library_folder.dart';

final libraryFoldersProvider = Provider(
  (ref) => ref.watch(libraryRepositoryProvider).loadFolders(),
);

// reloads when the scan finishes
final libraryTracksProvider = Provider((ref) {
  ref.watch(libraryRefreshProvider);
  return ref.watch(libraryRepositoryProvider).loadTracks();
});

final libraryProvider = NotifierProvider(LibraryNotifier.new);

class LibraryNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addFolder() async {
    final path = await getDirectoryPath();
    if (path == null) return;

    final library = ref.read(libraryRepositoryProvider);
    library.addFolder(path);
    ref.invalidate(libraryFoldersProvider);
    await library.refresh();
    ref.invalidate(libraryTracksProvider);
  }

  Future<void> removeFolder(LibraryFolder folder) async {
    final library = ref.read(libraryRepositoryProvider);
    library.removeFolder(folder);
    ref.invalidate(libraryFoldersProvider);
    await library.refresh();
    ref.invalidate(libraryTracksProvider);
  }
}
