import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/playback_notifier.dart';
import '../../../utils/format.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final playing = ref.watch(
      playbackProvider.select((state) => state.playing),
    );
    final playback = ref.read(playbackProvider.notifier);

    var icon = Icons.play_arrow_rounded;
    var tooltip = 'Play';
    if (playing) {
      icon = Icons.pause_rounded;
      tooltip = 'Pause';
    }
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: Border(top: BorderSide(color: theme.dividerColor)),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 200,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                titleTextStyle: theme.textTheme.titleSmall,
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  byline(track.artist, track.genres),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              iconSize: 28,
              icon: Icon(icon),
              tooltip: tooltip,
              onPressed: () => playback.toggle(track),
            ),
            const SizedBox(width: 16),
            const Spacer(),
            const SizedBox(width: 12),
            const _Time(),
          ],
        ),
      ),
    );
  }
}

class _Time extends ConsumerWidget {
  const _Time();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
