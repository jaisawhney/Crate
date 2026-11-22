import 'package:material_ui/material_ui.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detail;
  final bool selected;
  final bool playing;
  final VoidCallback onPlay;

  const SongTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.detail,
    required this.selected,
    required this.playing,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;

    var icon = Icons.play_arrow_rounded;
    var tooltip = 'Play';
    if (playing) {
      icon = Icons.pause_rounded;
      tooltip = 'Pause';
    }
    return ListTile(
      selected: selected,
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detail != null) Text(detail, style: theme.textTheme.labelMedium),
          IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPlay),
        ],
      ),
      onTap: onPlay,
    );
  }
}
