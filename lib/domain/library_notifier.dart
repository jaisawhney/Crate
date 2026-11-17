import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dependencies.dart';
import '../data/services/database/library_folder.dart';

final libraryFoldersProvider = Provider(
  (ref) => ref.watch(libraryRepositoryProvider).loadFolders(),
);

final libraryProvider = NotifierProvider(LibraryNotifier.new);

class LibraryNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addFolder() async {
    final path = await getDirectoryPath();
    if (path == null) return;

    ref.read(libraryRepositoryProvider).addFolder(path);
    ref.invalidate(libraryFoldersProvider);
  }

  void removeFolder(LibraryFolder folder) {
    ref.read(libraryRepositoryProvider).removeFolder(folder);
    ref.invalidate(libraryFoldersProvider);
  }
}
