import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/library_notifier.dart';
import '../../../domain/playback_notifier.dart';
import '../../../utils/format.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/panel.dart';
import '../../core/ui/song_tile.dart';
import '../view_models/discover_view_model.dart';
import 'genre_colors.dart';

class ResultsPanel extends ConsumerWidget {
  const ResultsPanel({super.key});

  static const _partial =
      'Still analyzing your library, some songs are missing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyzing = ref.watch(analyzingProvider);
    final moment = ref.watch(momentQueryProvider);
    if (moment != null) {
      var subtitle =
          'Songs that sound like it around ${formatDuration(moment.start)}';
      if (analyzing) subtitle = _partial;
      return Panel(
        title: 'Similar to ${moment.track.title}',
        subtitle: subtitle,
        trailing: TextButton(
          onPressed: ref.read(discoverViewModelProvider.notifier).clearMoment,
          child: const Text('Back'),
        ),
        child: _matches(context, ref),
      );
    }

    final query = ref.watch(queryProvider);
    if (query.isEmpty) {
      return Panel(
        title: 'Matches',
        subtitle: 'Search for a sound to see them here',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Describe what you want to hear, like a quiet piano intro or a '
              'crowd cheering, and jump straight to the part of each song '
              'that sounds like it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    var subtitle = 'Each song plays from the part that fits best';
    if (analyzing) subtitle = _partial;
    return Panel(
      title: 'Matches',
      subtitle: subtitle,
      child: _matches(context, ref),
    );
  }

  Widget _matches(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final viewModel = ref.read(discoverViewModelProvider.notifier);
    final playback = ref.watch(playbackProvider);
    final slots = ref.watch(comparedGenresProvider);
    final highlighted = ref.watch(highlightProvider);
    final search = ref.watch(searchResultsProvider);

    return search.when(
      data: (results) => ListView.separated(
        itemCount: results.length.clamp(0, 30),
        separatorBuilder: (context, idx) => const Divider(),
        itemBuilder: (context, idx) {
          final result = results[idx];
          final track = result.track;
          return MouseRegion(
            onEnter: (event) => viewModel.highlight(track.id),
            onExit: (event) => viewModel.highlight(null),
            child: SongTile(
              title: track.title,
              subtitle: byline(track.artist, track.genres),
              detail: 'at ${formatDuration(result.start)}',
              color: matchColor(colors, slots, track.genres),
              selected: playback.isCurrent(track),
              highlighted: highlighted == track.id,
              playing: playback.isPlaying(track),
              onPlay: () => viewModel.playOrPause(result),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          EmptyState(title: 'Search failed', message: '$error'),
    );
  }
}
