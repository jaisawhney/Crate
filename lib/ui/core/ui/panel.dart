import 'package:material_ui/material_ui.dart';

class Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const Panel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              visualDensity: VisualDensity.compact,
              titleTextStyle: theme.textTheme.titleMedium,
              subtitleTextStyle: theme.textTheme.bodySmall,
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: switch (subtitle) {
                final subtitle? => Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                null => null,
              },
              trailing: trailing,
            ),
            const SizedBox(height: 8),
            // tiles paint on the nearest Material, so it's clipped to the panel
            Expanded(
              child: ClipRect(
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
