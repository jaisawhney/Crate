import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/library_notifier.dart';
import '../../core/ui/empty_state.dart';
import '../../discover/widgets/discover_screen.dart';
import '../../discover/widgets/now_playing_bar.dart';
import '../../library/widgets/library_screen.dart';
import '../view_models/shell_view_model.dart';
import 'model_download_card.dart';
import 'sidebar.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            index: _index,
            onSelect: (idx) => setState(() => _index = idx),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final ready = ref.watch(libraryReadyProvider);
    if (ready.isLoading) return _loading();
    if (ready.hasError) {
      return EmptyState(
        title: "Couldn't load SonicEmbed",
        message: '${ready.error}',
        action: FilledButton(
          onPressed: ref.read(shellViewModelProvider.notifier).retry,
          child: const Text('Retry'),
        ),
      );
    }

    final folders = ref.watch(libraryFoldersProvider).value;
    if (folders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (folders.isEmpty) {
      return EmptyState(
        icon: Icons.library_music_outlined,
        title: 'No music yet',
        action: FilledButton(
          onPressed: ref.read(libraryProvider.notifier).addFolder,
          child: const Text('Add folder'),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _index,
            children: const [DiscoverScreen(), LibraryScreen()],
          ),
        ),
        const NowPlayingBar(),
      ],
    );
  }

  Widget _loading() {
    final progress = ref.watch(downloadProgressProvider);
    if (progress == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ModelDownloadCard(progress: progress);
  }
}
