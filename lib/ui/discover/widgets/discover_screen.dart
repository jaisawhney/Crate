import 'package:material_ui/material_ui.dart';

import '../../core/ui/page_header.dart';
import '../../core/ui/panel.dart';
import 'results_panel.dart';
import 'search_field.dart';
import 'sound_map.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              overline: 'Discover',
              title: 'Hear what you describe',
              subtitle:
                  'Describe a sound to jump to where it happens. The map '
                  'groups songs by how they sound, so you can see if your '
                  'genre tags agree.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: Panel(
                      title: 'Sound map',
                      subtitle:
                          'Songs that sound alike sit close together · one '
                          'dot per song',
                      child: SoundMap(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: (constraints.maxWidth / 3).clamp(320, 480),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SearchField(),
                        SizedBox(height: 12),
                        Expanded(child: ResultsPanel()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
