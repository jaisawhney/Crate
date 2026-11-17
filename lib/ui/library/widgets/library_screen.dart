import 'package:material_ui/material_ui.dart';

import '../../core/ui/page_header.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            overline: 'Library',
            title: 'Your music',
            subtitle: 'Every song in your music folders',
          ),
        ],
      ),
    );
  }
}
