import 'package:path/path.dart' as p;

import '../../services/database/library_database_service.dart';
import '../../services/database/library_folder.dart';

class LibraryRepository {
  final LibraryDatabaseService _database;

  LibraryRepository({required this._database});

  List<LibraryFolder> loadFolders() => _database.loadFolders();

  void addFolder(String path) {
    _database.saveFolder(LibraryFolder(path: p.normalize(path)));
  }

  void removeFolder(LibraryFolder folder) => _database.removeFolder(folder.id);
}
