import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/library/library_repository.dart';
import '../data/repositories/player/player_repository.dart';
import '../data/services/audio_decoder.dart';
import '../data/services/database/library_database_service.dart';
import '../data/services/model_download_service.dart';
import '../data/services/sonic_embed.dart';

final libraryDatabaseServiceProvider = Provider<LibraryDatabaseService>(
  (ref) => throw UnimplementedError(),
);

final audioDecoderProvider = Provider<AudioDecoder>(
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

final libraryRepositoryProvider = FutureProvider((ref) async {
  return LibraryRepository(
    database: ref.watch(libraryDatabaseServiceProvider),
    decoder: ref.watch(audioDecoderProvider),
    sonicEmbed: await ref.watch(sonicEmbedProvider.future),
  );
});

final playerRepositoryProvider = Provider((ref) {
  final player = PlayerRepository();
  ref.onDispose(player.dispose);
  return player;
});

final libraryRefreshProvider = FutureProvider((ref) async {
  final library = await ref.watch(libraryRepositoryProvider.future);
  await library.refresh();
});
