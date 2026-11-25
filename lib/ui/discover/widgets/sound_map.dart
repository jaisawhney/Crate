import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/playback_notifier.dart';
import '../../../models/map_point.dart';
import '../../../utils/format.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../view_models/discover_view_model.dart';
import 'genre_colors.dart';
import 'genre_list.dart';

class SoundMap extends ConsumerStatefulWidget {
  const SoundMap({super.key});

  @override
  ConsumerState<SoundMap> createState() => _SoundMapState();
}

class _SoundMapState extends ConsumerState<SoundMap> {
  final _zoom = TransformationController();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(musicMapProvider);
    final points = map.value ?? const <MapPoint>[];
    if (points.isEmpty && map.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (points.isEmpty) {
      return const EmptyState(
        icon: Icons.scatter_plot_outlined,
        title: 'Nothing to map yet',
        message: 'Songs show up here once they are analyzed.',
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(width: 210, child: GenreList()),
        const SizedBox(width: 16),
        Expanded(child: _plot(points)),
      ],
    );
  }

  Widget _plot(List<MapPoint> points) {
    final theme = Theme.of(context);
    final songs = _spots(points);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              // keeps every dot from redrawing with each player tick
              child: RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _chart(songs, _bounds(points, constraints.biggest)),
                ),
              ),
            ),
            Positioned(top: 4, right: 4, child: _resetZoom()),
          ],
        ),
      ),
    );
  }

  Widget _resetZoom() {
    return ValueListenableBuilder(
      valueListenable: _zoom,
      builder: (context, matrix, child) {
        if (matrix.getMaxScaleOnAxis() == 1) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.zoom_out_map),
          tooltip: 'Show the whole map',
          onPressed: () => _zoom.value = Matrix4.identity(),
        );
      },
    );
  }

  Widget _chart(Map<ScatterSpot, MapPoint> songs, Rect bounds) {
    final theme = Theme.of(context);
    final viewModel = ref.read(discoverViewModelProvider.notifier);
    final grid = FlLine(
      color: theme.dividerColor.withValues(alpha: 0.3),
      strokeWidth: 1,
    );

    return ScatterChart(
      ScatterChartData(
        scatterSpots: songs.keys.toList(),
        minX: bounds.left,
        maxX: bounds.right,
        minY: bounds.top,
        maxY: bounds.bottom,
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          verticalInterval: bounds.width / 4,
          horizontalInterval: bounds.height / 4,
          getDrawingVerticalLine: (value) => grid,
          getDrawingHorizontalLine: (value) => grid,
        ),
        clipData: const FlClipData.all(),
        scatterTouchData: ScatterTouchData(
          touchSpotThreshold: 6,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (spot) =>
                theme.colorScheme.surfaceContainerHighest,
            tooltipBorderRadius: BorderRadius.circular(8),
            maxContentWidth: 240,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spot) {
              final track = songs[spot]!.track;
              return ScatterTooltipItem(
                track.title,
                textStyle: theme.textTheme.labelLarge,
                textAlign: TextAlign.start,
                children: [
                  TextSpan(
                    text: '\n${byline(track.artist, track.genres)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
          mouseCursorResolver: (event, response) {
            if (response?.touchedSpot == null) return MouseCursor.defer;
            return SystemMouseCursors.click;
          },
          touchCallback: (event, response) {
            final touched = response?.touchedSpot;
            if (event is! FlTapUpEvent || touched == null) return;
            viewModel.playTrack(songs[touched.spot]!.track);
          },
        ),
      ),
      // fl_chart animates spots by list position, and brightness reorders them
      duration: Duration.zero,
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.free,
        maxScale: 12,
        trackpadScrollCausesScale: true,
        transformationController: _zoom,
      ),
    );
  }

  // fl_chart draws spots in order, so the brightest and the rings go last
  Map<ScatterSpot, MapPoint> _spots(List<MapPoint> points) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final slots = ref.watch(comparedGenresProvider);
    final brightness = _brightness(points, slots);
    final order = List.generate(points.length, (idx) => idx)
      ..sort((a, b) => brightness[a].compareTo(brightness[b]));

    final spots = <ScatterSpot, MapPoint>{};
    for (final idx in order) {
      final point = points[idx];
      final color = matchColor(colors, slots, point.track.genres);
      final dot = FlDotCirclePainter(
        radius: 3.25,
        color: color.withValues(alpha: 0.15 + 0.85 * brightness[idx]),
        strokeColor: theme.colorScheme.surfaceContainerLowest,
        strokeWidth: 1,
      );
      spots[ScatterSpot(point.x, point.y, dotPainter: dot)] = point;
    }

    final highlightId = ref.watch(highlightProvider);
    final currentId = ref.watch(currentTrackProvider)?.id;
    for (final point in points) {
      final id = point.track.id;
      if (id != highlightId && id != currentId) continue;

      var radius = 7.0;
      var width = 1.5;
      if (id == currentId) {
        radius = 9;
        width = 2;
      }
      final ring = FlDotCirclePainter(
        radius: radius,
        color: Colors.transparent,
        strokeColor: theme.colorScheme.onSurface,
        strokeWidth: width,
      );
      spots[ScatterSpot(point.x, point.y, dotPainter: ring)] = point;
    }
    return spots;
  }

  // fl_chart stretches each axis to fit, so the shorter side gets padding
  Rect _bounds(List<MapPoint> points, Size size) {
    final xs = points.map((point) => point.x);
    final ys = points.map((point) => point.y);
    final data = Rect.fromLTRB(
      xs.reduce(min),
      ys.reduce(min),
      xs.reduce(max),
      ys.reduce(max),
    );
    final unit = max(data.width / size.width, data.height / size.height);
    return Rect.fromCenter(
      center: data.center,
      width: size.width * unit * 1.06,
      height: size.height * unit * 1.06,
    );
  }

  List<double> _brightness(List<MapPoint> points, List<String?> slots) {
    final matchScores = ref.watch(matchScoresProvider);
    if (matchScores.isEmpty) {
      return [
        for (final point in points)
          if (mainSlot(slots, point.track.genres) == null) 0.35 else 0.7,
      ];
    }

    final brightness = <double>[];
    for (final point in points) {
      final share = matchScores[point.track.id] ?? 0;
      // cubed, so only the closest matches stay bright
      brightness.add(share * share * share);
    }
    return brightness;
  }
}
