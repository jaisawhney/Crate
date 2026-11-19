import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationDrawer(
      selectedIndex: 0,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset('assets/icon/crate.svg', width: 40, height: 40),
            const SizedBox(height: 12),
            Text('Crate', style: theme.textTheme.titleMedium),
            Text(
              'Search your music by sound',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      children: const [
        NavigationDrawerDestination(
          icon: Icon(Icons.library_music_outlined),
          label: Text('Library'),
        ),
      ],
    );
  }
}
