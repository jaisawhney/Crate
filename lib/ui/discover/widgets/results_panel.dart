import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/library_notifier.dart';
import '../../../utils/format.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/panel.dart';
import '../view_models/discover_view_model.dart';

class ResultsPanel extends ConsumerWidget {
  const ResultsPanel({super.key});

  static const _partial =
      'Still analyzing your library, some songs are missing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyzing = ref.watch(analyzingProvider);
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
              'crowd cheering, and find the part of each song that sounds '
              'like it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    var subtitle = 'Each song with the part that fits best';
    if (analyzing) subtitle = _partial;
    return Panel(
      title: 'Matches',
      subtitle: subtitle,
      child: _matches(context, ref),
    );
  }

  Widget _matches(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final search = ref.watch(searchResultsProvider);

    return search.when(
      data: (results) => ListView.separated(
        itemCount: results.length.clamp(0, 30),
        separatorBuilder: (context, idx) => const Divider(),
        itemBuilder: (context, idx) {
          final result = results[idx];
          final track = result.track;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              byline(track.artist, track.genres),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              'at ${formatDuration(result.start)}',
              style: theme.textTheme.labelMedium,
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
