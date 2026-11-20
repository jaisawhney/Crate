import 'package:material_ui/material_ui.dart';

import '../../../models/model_download_progress.dart';

class ModelDownloadCard extends StatelessWidget {
  final ModelDownloadProgress progress;

  const ModelDownloadCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    'Getting ready to listen',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    'Crate uses SonicEmbed, an embedding model, to hear what '
                    'your songs sound like.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.manage_search),
                    title: Text('Search by sound'),
                    subtitle: Text(
                      'Describe a sound and jump to where it happens in '
                      'your songs',
                    ),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline),
                    title: Text('Stays on your computer'),
                    subtitle: Text(
                      'Your songs are analyzed on device and never uploaded',
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress.fraction,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Text(
                    progress.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
