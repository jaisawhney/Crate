import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/library_notifier.dart';

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
      footer: const _AnalysisStatus(),
      children: const [
        NavigationDrawerDestination(
          icon: Icon(Icons.library_music_outlined),
          label: Text('Library'),
        ),
      ],
    );
  }
}

class _AnalysisStatus extends ConsumerWidget {
  const _AnalysisStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(analysisProgressProvider).value;
    if (progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(progress.label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.fraction,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
