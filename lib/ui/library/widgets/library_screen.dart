import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../domain/library_notifier.dart';
import '../../../domain/playback_notifier.dart';
import '../../../utils/format.dart';
import '../../core/ui/page_header.dart';
import '../../core/ui/panel.dart';
import '../../core/ui/song_tile.dart';
import '../view_models/library_view_model.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(tracksProvider).length;
    final length = ref.watch(libraryLengthProvider);
    final library = ref.read(libraryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Library',
            subtitle: '$songs songs · ${formatHours(length)}',
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
              children: [
                SizedBox(width: 280, child: _Folders()),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SongSearch(),
                      SizedBox(height: 12),
                      Expanded(child: _Songs()),
                    ],
                  ),
                ),
              ],
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
    final folders = ref.watch(libraryFoldersProvider).value ?? const [];
    final counts = ref.watch(folderSongCountsProvider);
    final library = ref.read(libraryProvider.notifier);

    return Panel(
      title: 'Folders',
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
                  subtitle: Text('${counts[folder.id] ?? 0} songs'),
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

class _SongSearch extends ConsumerWidget {
  const _SongSearch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchBar(
      hintText: 'Search songs',
      leading: const Icon(Icons.search),
      onChanged: ref.read(songSearchProvider.notifier).set,
    );
  }
}

class _Songs extends ConsumerWidget {
  const _Songs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(foundTracksProvider);
    final total = ref.watch(tracksProvider).length;
    final playback = ref.read(playbackProvider.notifier);
    final playbackState = ref.watch(playbackProvider);

    String? subtitle;
    if (tracks.length < total) subtitle = '${tracks.length} of $total songs';
    return Panel(
      title: 'Songs',
      subtitle: subtitle,
      child: ListView.separated(
        itemCount: tracks.length,
        separatorBuilder: (context, idx) => const Divider(),
        itemBuilder: (context, idx) {
          final track = tracks[idx];
          final duration = track.duration;
          String? length;
          if (duration != null) length = formatDuration(duration);
          return SongTile(
            title: track.title,
            subtitle: byline(track.artist, track.genres),
            detail: length,
            selected: playbackState.isCurrent(track),
            playing: playbackState.isPlaying(track),
            onPlay: () => playback.toggle(track),
          );
        },
      ),
    );
  }
}
