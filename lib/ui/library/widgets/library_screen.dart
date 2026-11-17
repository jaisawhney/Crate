import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../domain/library_notifier.dart';
import '../../core/ui/page_header.dart';
import '../../core/ui/panel.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.read(libraryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            overline: 'Library',
            title: 'Your music',
            subtitle: 'Every song in your music folders',
            trailing: FilledButton.tonalIcon(
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add folder'),
              onPressed: library.addFolder,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [SizedBox(width: 280, child: _Folders())],
            ),
          ),
        ],
      ),
    );
  }
}

class _Folders extends ConsumerWidget {
  const _Folders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(libraryFoldersProvider);
    final library = ref.read(libraryProvider.notifier);

    return Panel(
      title: 'Folders',
      subtitle: 'Where your songs come from',
      child: ListView(
        children: [
          for (final folder in folders)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tooltip(
                message: folder.path,
                child: ListTile(
                  tileColor: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  contentPadding: const EdgeInsets.only(left: 14, right: 4),
                  leading: Icon(
                    Icons.folder_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    p.basename(folder.path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove folder',
                    onPressed: () => library.removeFolder(folder),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
