import 'package:material_ui/material_ui.dart';

import '../../core/ui/page_header.dart';
import 'results_panel.dart';
import 'search_field.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            overline: 'Discover',
            title: 'Hear what you describe',
            subtitle: 'Describe a sound to jump to where it happens.',
          ),
          SizedBox(height: 16),
          SearchField(),
          SizedBox(height: 12),
          Expanded(child: ResultsPanel()),
        ],
      ),
    );
  }
}
