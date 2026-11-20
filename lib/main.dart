import 'package:material_ui/material_ui.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart' show FlutterEdgeAi;
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/dependencies.dart';
import 'data/services/audio_decoder.dart';
import 'data/services/database/library_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final database = await LibraryDatabaseService.open();
  final decoder = await AudioDecoder.load();

  runApp(
    ProviderScope(
      // riverpod retries failed providers for ~40 s by default, hiding a failed download behind a spinner
      retry: (retryCount, error) => null,
      overrides: [
        libraryDatabaseServiceProvider.overrideWithValue(database),
        audioDecoderProvider.overrideWithValue(decoder),
      ],
      child: const CrateApp(),
    ),
  );
}
