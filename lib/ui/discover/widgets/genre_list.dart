import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/theme.dart';
import '../view_models/discover_view_model.dart';

class GenreList extends ConsumerWidget {
  const GenreList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.read(discoverViewModelProvider.notifier);
    final counts = ref.watch(genreCountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Genres', style: theme.textTheme.labelLarge)),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: viewModel.resetGenres,
              child: const Text('Top $defaultGenreCount'),
            ),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: viewModel.clearGenres,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // tiles paint on the nearest Material, so it's clipped to the list
        Expanded(
          child: ClipRect(
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                children: [
                  for (final MapEntry(key: genre, value: count)
                      in counts.entries)
                    _GenreToggle(genre: genre, count: count),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 4,
              backgroundColor: AppColors.of(context).noMatch,
            ),
            const SizedBox(width: 10),
            Text('Other songs', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _GenreToggle extends ConsumerWidget {
  final String genre;
  final int count;

  const _GenreToggle({required this.genre, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.read(discoverViewModelProvider.notifier);
    final slots = ref.watch(comparedGenresProvider);
    final slot = slots.indexOf(genre);
    final checked = slot != -1;
    final colorsTaken = slots.nonNulls.length >= maxComparedGenres;

    var color = theme.colorScheme.outline;
    var edge = theme.dividerColor;
    if (checked) {
      color = AppColors.of(context).genres[slot];
      edge = color.withValues(alpha: 0.5);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CheckboxListTile(
        value: checked,
        onChanged: (value) => viewModel.toggleGenre(genre),
        enabled: checked || !colorsTaken,
        selected: checked,
        dense: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        checkboxScaleFactor: 0.8,
        horizontalTitleGap: 6,
        minTileHeight: 34,
        minVerticalPadding: 0,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.only(left: 4, right: 12),
        activeColor: color,
        checkColor: theme.colorScheme.surface,
        selectedTileColor: color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: edge),
        ),
        title: Tooltip(
          message: genre,
          waitDuration: const Duration(milliseconds: 500),
          child: Text(
            genre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
        secondary: Text('$count', style: theme.textTheme.bodySmall),
      ),
    );
  }
}
