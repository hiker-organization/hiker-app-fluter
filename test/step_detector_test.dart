import 'dart:math';

import 'package:app_hiker/src/utils/step_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _gravity = 9.81;
const _sampleRate = 50; // Hz, close to SensorInterval.gameInterval.

// Feeds [seconds] of a vertical acceleration oscillating [frequency] times per second
// with the given [amplitude] (m/s²) and returns how many steps were detected.
int _countSteps({
  required double seconds,
  required double frequency,
  required double amplitude,
  double noise = 0,
  int seed = 1,
}) {
  final detector = StepDetector();
  final random = Random(seed);
  final start = DateTime(2026);
  var steps = 0;
  final samples = (seconds * _sampleRate).round();

  for (var i = 0; i < samples; i++) {
    final t = i / _sampleRate;
    final jitter = (random.nextDouble() * 2 - 1) * noise;
    final z = _gravity + amplitude * sin(2 * pi * frequency * t) + jitter;
    final timestamp = start.add(Duration(microseconds: (t * 1e6).round()));
    if (detector.addSample(0.3, 0.2, z, timestamp)) steps++;
  }
  return steps;
}

void main() {
  test('counts one step per oscillation while walking', () {
    // 2 steps per second for 30 s.
    final steps = _countSteps(seconds: 30, frequency: 2, amplitude: 3);
    expect(steps, inInclusiveRange(55, 61));
  });

  test('handles noisy walking', () {
    final steps = _countSteps(seconds: 30, frequency: 1.8, amplitude: 3, noise: 0.8);
    expect(steps, inInclusiveRange(48, 56));
  });

  test('counts gentle walking', () {
    // Slow, soft steps (phone in the pocket of someone walking calmly).
    final steps = _countSteps(seconds: 30, frequency: 1.6, amplitude: 1.2, noise: 0.3);
    expect(steps, inInclusiveRange(44, 50));
  });

  test('counts brisk walking', () {
    final steps = _countSteps(seconds: 30, frequency: 2.4, amplitude: 2, noise: 0.5);
    expect(steps, inInclusiveRange(68, 74));
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
}
