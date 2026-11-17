import 'package:material_ui/material_ui.dart';

import 'ui/core/themes/theme.dart';
import 'ui/shell/widgets/home_shell.dart';

class CrateApp extends StatelessWidget {
  const CrateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crate',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
