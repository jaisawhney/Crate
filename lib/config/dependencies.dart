import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/library/library_repository.dart';
import '../data/services/database/library_database_service.dart';
import '../data/services/model_download_service.dart';
import '../data/services/sonic_embed.dart';

final libraryDatabaseServiceProvider = Provider<LibraryDatabaseService>(
  (ref) => throw UnimplementedError(),
);

final modelDownloadServiceProvider = Provider((ref) => ModelDownloadService());

final modelDownloadProgressProvider = StreamProvider(
  (ref) => ref.watch(modelDownloadServiceProvider).watchProgress(),
);

final sonicEmbedProvider = FutureProvider((ref) async {
  final bundle = await ref.watch(modelDownloadServiceProvider).download();
  return SonicEmbed.load(bundle);
});

final libraryRepositoryProvider = Provider(
  (ref) =>
      LibraryRepository(database: ref.watch(libraryDatabaseServiceProvider)),
);

final libraryRefreshProvider = FutureProvider(
  (ref) => ref.watch(libraryRepositoryProvider).refresh(),
);
