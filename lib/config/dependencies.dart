import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/library/library_repository.dart';
import '../data/services/database/library_database_service.dart';

final libraryDatabaseServiceProvider = Provider<LibraryDatabaseService>(
  (ref) => throw UnimplementedError(),
);

final libraryRepositoryProvider = Provider(
  (ref) =>
      LibraryRepository(database: ref.watch(libraryDatabaseServiceProvider)),
);

final libraryRefreshProvider = FutureProvider(
  (ref) => ref.watch(libraryRepositoryProvider).refresh(),
);
