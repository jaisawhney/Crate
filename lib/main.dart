import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/dependencies.dart';
import 'data/services/database/library_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await LibraryDatabaseService.open();

  runApp(
    ProviderScope(
      overrides: [libraryDatabaseServiceProvider.overrideWithValue(database)],
      child: const CrateApp(),
    ),
  );
}
