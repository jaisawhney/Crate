import 'dart:math';
import 'dart:typed_data';

import 'package:ml_linalg/matrix.dart';

import '../models/point2d.dart';

// standard t-SNE for unit vectors
class Tsne {
  static const _perplexity = 30.0;
  static const _iterations = 1000;
  static const _learningRate = 100.0;

  static List<Point2D> run(List<List<double>> vectors) {
    final count = vectors.length;
    final matrix = Matrix.fromList(vectors);
    final affinities = _affinities(matrix * matrix.transpose(), count);

    // a fixed seed draws the same map every time
    final random = Random(0);
    final points = Float64List(count * 2);
    for (var idx = 0; idx < points.length; idx++) {
      points[idx] = (random.nextDouble() - 0.5) * 1e-4;
    }
    final velocity = Float64List(count * 2);
    final attraction = Float64List(count * 2);
    final repulsion = Float64List(count * 2);

    for (var iteration = 0; iteration < _iterations; iteration++) {
      // exaggerated affinities pull neighbors into groups first
      var exaggeration = 1.0;
      var momentum = 0.8;
      if (iteration < 250) {
        exaggeration = 12;
        momentum = 0.5;
      }

      attraction.fillRange(0, attraction.length, 0);
      repulsion.fillRange(0, repulsion.length, 0);
      var closenessSum = 0.0;
      for (var idx = 0; idx < count; idx++) {
        for (var other = idx + 1; other < count; other++) {
          final dx = points[idx * 2] - points[other * 2];
          final dy = points[idx * 2 + 1] - points[other * 2 + 1];
          final closeness = 1 / (1 + dx * dx + dy * dy);
          closenessSum += 2 * closeness;

          final pull =
              exaggeration * affinities[idx * count + other] * closeness;
          attraction[idx * 2] += pull * dx;
          attraction[idx * 2 + 1] += pull * dy;
          attraction[other * 2] -= pull * dx;
          attraction[other * 2 + 1] -= pull * dy;

          final push = closeness * closeness;
          repulsion[idx * 2] += push * dx;
          repulsion[idx * 2 + 1] += push * dy;
          repulsion[other * 2] -= push * dx;
          repulsion[other * 2 + 1] -= push * dy;
        }
      }

      for (var idx = 0; idx < points.length; idx++) {
        final gradient = 4 * (attraction[idx] - repulsion[idx] / closenessSum);
        velocity[idx] = momentum * velocity[idx] - _learningRate * gradient;
        points[idx] += velocity[idx];
      }
    }

    return _alongWidestSpread(points, count);
  }

  // how likely each point is to pick each other point as its neighbor
  static Float64List _affinities(Matrix similarities, int count) {
    final conditional = Float64List(count * count);
    for (var idx = 0; idx < count; idx++) {
      final row = similarities[idx];
      // a point's distance to itself would turn the sums into NaN
      final others = [
        for (var other = 0; other < count; other++)
          if (other != idx) other,
      ];
      // measured from the nearest neighbor so exp() doesn't underflow
      final squared = [for (final other in others) 2 - 2 * row[other]];
      final nearest = squared.reduce(min);
      final distances = [for (final distance in squared) distance - nearest];
      final precision = _precisionFor(distances);

      final weights = [
        for (final distance in distances) exp(-precision * distance),
      ];
      final weightSum = weights.reduce((a, b) => a + b);
      for (var position = 0; position < others.length; position++) {
        conditional[idx * count + others[position]] =
            weights[position] / weightSum;
      }
    }

    final joint = Float64List(count * count);
    for (var idx = 0; idx < count; idx++) {
      for (var other = 0; other < count; other++) {
        final both =
            conditional[idx * count + other] + conditional[other * count + idx];
        joint[idx * count + other] = max(both / (2 * count), 1e-12);
      }
    }
    return joint;
  }

  // binary search for the spread that gives about _perplexity neighbors
  static double _precisionFor(List<double> distances) {
    final target = log(_perplexity);
    var precision = 1.0;
    var low = 0.0;
    var high = double.infinity;
    for (var step = 0; step < 50; step++) {
      var weightSum = 0.0;
      var weightedDistance = 0.0;
      for (final distance in distances) {
        final weight = exp(-precision * distance);
        weightSum += weight;
        weightedDistance += weight * distance;
      }
      final entropy = log(weightSum) + precision * weightedDistance / weightSum;
      if ((entropy - target).abs() < 1e-5) break;

      if (entropy < target) {
        high = precision;
        precision = (precision + low) / 2;
        continue;
      }
      low = precision;
      if (high.isInfinite) {
        precision *= 2;
        continue;
      }
      precision = (precision + high) / 2;
    }
    return precision;
  }

  // t-SNE's rotation is arbitrary, so the widest spread is turned sideways
  static List<Point2D> _alongWidestSpread(Float64List points, int count) {
    var meanX = 0.0;
    var meanY = 0.0;
    for (var idx = 0; idx < count; idx++) {
      meanX += points[idx * 2] / count;
      meanY += points[idx * 2 + 1] / count;
    }

    var xx = 0.0;
    var yy = 0.0;
    var xy = 0.0;
    for (var idx = 0; idx < count; idx++) {
      final dx = points[idx * 2] - meanX;
      final dy = points[idx * 2 + 1] - meanY;
      xx += dx * dx;
      yy += dy * dy;
      xy += dx * dy;
    }
    final angle = atan2(2 * xy, xx - yy) / 2;
    final cosine = cos(angle);
    final sine = sin(angle);

    final turned = <Point2D>[];
    for (var idx = 0; idx < count; idx++) {
      final dx = points[idx * 2] - meanX;
      final dy = points[idx * 2 + 1] - meanY;
      turned.add(Point2D(dx * cosine + dy * sine, dy * cosine - dx * sine));
    }
    return turned;
  }
}
