import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/library_notifier.dart';
import '../../core/ui/empty_state.dart';
import '../../library/widgets/library_screen.dart';
import 'sidebar.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(child: _body(ref)),
        ],
      ),
    );
  }

  Widget _body(WidgetRef ref) {
    final folders = ref.watch(libraryFoldersProvider);
    if (folders.isEmpty) {
      return EmptyState(
        icon: Icons.library_music_outlined,
        title: 'Add your music',
        message: 'Pick the folder that holds your songs.',
        action: FilledButton(
          onPressed: ref.read(libraryProvider.notifier).addFolder,
          child: const Text('Add music folder'),
        ),
      );
    }

    return const LibraryScreen();
  }
}
