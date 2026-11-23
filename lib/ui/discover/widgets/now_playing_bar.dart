import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/playback_notifier.dart';
import '../../../utils/format.dart';
import '../../core/themes/theme.dart';
import '../view_models/discover_view_model.dart';

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
    final scores = ref.watch(momentScoresProvider).value ?? const [];

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
            const _Cover(),
            const SizedBox(width: 14),
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Timeline(),
                  if (scores.isNotEmpty)
                    Text(
                      'Amber shows where this song matches best',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _Time(),
          ],
        ),
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final cover = ref.watch(coverProvider).value;

    Widget picture = ColoredBox(
      color: colors.primaryContainer,
      child: Icon(Icons.music_note, color: colors.onPrimaryContainer),
    );
    if (cover != null) {
      picture = Image.memory(
        cover,
        fit: BoxFit.cover,
        cacheWidth: (72 * MediaQuery.devicePixelRatioOf(context)).round(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(dimension: 72, child: picture),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final playback = ref.read(playbackProvider.notifier);

    void seek(Offset position) =>
        playback.seek(position.dx / context.size!.width);

    return GestureDetector(
      onTapDown: (details) => seek(details.localPosition),
      onHorizontalDragUpdate: (details) => seek(details.localPosition),
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(double.infinity, 44),
          painter: _TimelinePainter(
            levels: ref.watch(waveformProvider).value ?? const [],
            momentScores: ref.watch(momentScoresProvider).value ?? const [],
            progress: ref.watch(progressProvider),
            plain: colors.primary,
            cold: colors.outlineVariant,
            hot: AppColors.of(context).accentWarm,
            playhead: colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<double> levels;
  final List<double> momentScores;
  final double progress;
  final Color plain;
  final Color cold;
  final Color hot;
  final Color playhead;

  _TimelinePainter({
    required this.levels,
    required this.momentScores,
    required this.progress,
    required this.plain,
    required this.cold,
    required this.hot,
    required this.playhead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // bars keep their width, so a wider player shows more of them
    final bars = min(size.width ~/ 5, levels.length);
    final heat = _heat(bars);
    final step = size.width / bars;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var bar = 0; bar < bars; bar++) {
      final start = bar * levels.length ~/ bars;
      final end = (bar + 1) * levels.length ~/ bars;
      final level = levels.sublist(start, end).reduce(max);
      final height = (level * size.height).clamp(2.0, size.height);
      final x = step * (bar + 0.5);
      paint.color = plain;
      if (heat.isNotEmpty) paint.color = Color.lerp(cold, hot, heat[bar])!;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }

    final x = progress * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = playhead
        ..strokeWidth = 2,
    );
  }

  List<double> _heat(int bars) {
    if (momentScores.isEmpty) return const [];

    final heat = <double>[];
    for (var bar = 0; bar < bars; bar++) {
      final share = momentScores[bar * momentScores.length ~/ bars];
      heat.add(share * share);
    }
    return heat;
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) => true;
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
