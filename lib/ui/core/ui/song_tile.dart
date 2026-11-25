import 'package:material_ui/material_ui.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detail;
  final Color? color;
  final bool selected;
  final bool highlighted;
  final bool playing;
  final VoidCallback onPlay;

  const SongTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.detail,
    this.color,
    required this.selected,
    this.highlighted = false,
    required this.playing,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;
    final color = this.color;

    Widget? leading;
    if (color != null) {
      leading = CircleAvatar(radius: 5, backgroundColor: color);
    }
    var icon = Icons.play_arrow_rounded;
    var tooltip = 'Play';
    if (playing) {
      icon = Icons.pause_rounded;
      tooltip = 'Pause';
    }
    Color? background;
    if (highlighted) background = theme.colorScheme.surfaceContainerHigh;
    return ListTile(
      selected: selected,
      tileColor: background,
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      leading: leading,
      minLeadingWidth: 10,
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
