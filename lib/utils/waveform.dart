import 'dart:math';
import 'dart:typed_data';

List<double> waveform(Float32List samples, int bars) {
  final barLength = samples.length ~/ bars;
  final levels = <double>[];
  for (var bar = 0; bar < bars; bar++) {
    var sumOfSquares = 0.0;
    for (var idx = bar * barLength; idx < (bar + 1) * barLength; idx++) {
      sumOfSquares += samples[idx] * samples[idx];
    }
    levels.add(sqrt(sumOfSquares / max(barLength, 1)));
  }

  final loudest = levels.reduce(max);
  if (loudest == 0) return levels;
  return [for (final level in levels) level / loudest];
}
