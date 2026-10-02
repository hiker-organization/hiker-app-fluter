import 'dart:math';

// Counts steps from raw accelerometer samples (m/s², gravity included).
//
// Walking makes the acceleration magnitude oscillate around gravity once per step.
// The detector removes gravity with a slow moving average, smooths the remaining
// signal and counts a step each time it rises above [_upperThreshold], only after
// it went back below [_lowerThreshold] (hysteresis) and at least [_minStepInterval]
// after the previous step, which filters out shakes and double peaks.
class StepDetector {
  // Slow enough (~1 s at 50 Hz) to follow only gravity; a faster average followed the
  // walking oscillation itself and cancelled soft steps.
  static const _gravityAlpha = 0.98;
  static const _smoothingAlpha = 0.3;
  static const _upperThreshold = 0.6;
  static const _lowerThreshold = 0.2;
  static const _minStepInterval = Duration(milliseconds: 300);

  double? _gravity;
  double _smoothed = 0;
  bool _abovePeak = false;
  DateTime? _lastStep;

  // Returns true when the sample completes a step.
  bool addSample(double x, double y, double z, DateTime timestamp) {
    final magnitude = sqrt(x * x + y * y + z * z);
    _gravity = _gravity == null ? magnitude : _gravityAlpha * _gravity! + (1 - _gravityAlpha) * magnitude;
    _smoothed = (1 - _smoothingAlpha) * _smoothed + _smoothingAlpha * (magnitude - _gravity!);

    if (_abovePeak) {
      if (_smoothed < _lowerThreshold) _abovePeak = false;
      return false;
    }

    if (_smoothed > _upperThreshold &&
        (_lastStep == null || timestamp.difference(_lastStep!) >= _minStepInterval)) {
      _abovePeak = true;
      _lastStep = timestamp;
      return true;
    }
    return false;
  }

  // Called when tracking resumes so the pause doesn't affect the filters.
  void reset() {
    _gravity = null;
    _smoothed = 0;
    _abovePeak = false;
    _lastStep = null;
  }
}
