import 'dart:math';

import 'package:app_hiker/src/utils/step_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _gravity = 9.81;
const _sampleRate = 50; // Hz, close to SensorInterval.gameInterval.

// Feeds [seconds] of vertical acceleration given by [signal] (m/s², gravity excluded)
// and returns how many steps were counted.
int _countSignal(double seconds, double Function(double t, Random random) signal, {int seed = 1}) {
  final detector = StepDetector();
  final random = Random(seed);
  final start = DateTime(2026);
  var steps = 0;

  for (var i = 0; i < (seconds * _sampleRate).round(); i++) {
    final t = i / _sampleRate;
    final timestamp = start.add(Duration(microseconds: (t * 1e6).round()));
    steps += detector.addSample(0.3, 0.2, _gravity + signal(t, random), timestamp);
  }
  return steps;
}

double _noise(Random random, double amount) => (random.nextDouble() * 2 - 1) * amount;

// Steady walking: [frequency] steps per second.
int _countSteps({
  required double seconds,
  required double frequency,
  required double amplitude,
  double noise = 0,
}) {
  return _countSignal(seconds, (t, r) => amplitude * sin(2 * pi * frequency * t) + _noise(r, noise));
}

// Short bump centered at [center] seconds, like a single jolt of the phone.
double _bump(double t, double center, double amplitude) {
  final x = (t - center) / 0.06;
  return amplitude * exp(-x * x);
}

void main() {
  group('walking', () {
    test('counts one step per oscillation', () {
      // 2 steps per second for 30 s.
      final steps = _countSteps(seconds: 30, frequency: 2, amplitude: 3);
      expect(steps, inInclusiveRange(57, 61));
    });

    test('handles noisy walking', () {
      final steps = _countSteps(seconds: 30, frequency: 1.8, amplitude: 3, noise: 0.8);
      expect(steps, inInclusiveRange(50, 56));
    });

    test('counts gentle walking', () {
      // Slow, soft steps (phone in the pocket of someone walking calmly).
      final steps = _countSteps(seconds: 30, frequency: 1.6, amplitude: 1.2, noise: 0.3);
      expect(steps, inInclusiveRange(45, 49));
    });

    test('counts brisk walking', () {
      final steps = _countSteps(seconds: 30, frequency: 2.4, amplitude: 2, noise: 0.5);
      expect(steps, inInclusiveRange(69, 73));
    });

    test('keeps counting after stopping for a while', () {
      // 10 s walking, 4 s stopped, 10 s walking: about 40 steps. The first steps after
      // the stop are only confirmed later, but they are not lost.
      final steps = _countSignal(24, (t, r) {
        final walking = t < 10 || t >= 14;
        return (walking ? 2 * sin(2 * pi * 2 * t) : 0) + _noise(r, 0.3);
      });
      expect(steps, inInclusiveRange(37, 41));
    });
  });

  group('false steps', () {
    test('ignores putting the phone in the pocket', () {
      // Still, then three irregular jolts while the phone goes into the pocket, then still.
      final steps = _countSignal(8, (t, r) {
        return _bump(t, 2.0, 6) + _bump(t, 2.35, -4) + _bump(t, 2.5, 5) + _bump(t, 3.4, 4) + _noise(r, 0.3);
      });
      expect(steps, 0);
    });

    test('ignores handling the phone', () {
      // 15 s of jolts at irregular moments, like picking it up and typing.
      final jolts = <double>[];
      final random = Random(42);
      for (var t = 0.5; t < 15; t += 0.25 + random.nextDouble() * 1.8) {
        jolts.add(t);
      }
      final steps = _countSignal(16, (t, r) {
        return jolts.fold(0.0, (sum, center) => sum + _bump(t, center, 3 + (center * 7) % 3)) + _noise(r, 0.4);
      });
      expect(steps, lessThanOrEqualTo(4));
    });

    test('ignores a phone held still in the hand', () {
      final steps = _countSteps(seconds: 30, frequency: 2, amplitude: 0, noise: 0.5);
      expect(steps, 0);
    });

    test('ignores a phone lying still', () {
      final steps = _countSteps(seconds: 30, frequency: 2, amplitude: 0, noise: 0.2);
      expect(steps, 0);
    });

    test('does not count vibrations faster than a person can walk', () {
      // 8 Hz shaking would be 240 steps in 30 s; the minimum interval caps it.
      final steps = _countSteps(seconds: 30, frequency: 8, amplitude: 4);
      expect(steps, lessThanOrEqualTo(100));
    });
  });
}
