import 'package:material_ui/material_ui.dart';

import '../../library/widgets/library_screen.dart';
import 'sidebar.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        children: [
          Sidebar(),
          Expanded(child: LibraryScreen()),
        ],
      ),
    );
  }
}
