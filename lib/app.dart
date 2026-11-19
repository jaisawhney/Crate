import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/dependencies.dart';
import 'ui/core/themes/theme.dart';
import 'ui/shell/widgets/home_shell.dart';

class CrateApp extends ConsumerWidget {
  const CrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(libraryRefreshProvider, (previous, next) {});

    return MaterialApp(
      title: 'Crate',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
