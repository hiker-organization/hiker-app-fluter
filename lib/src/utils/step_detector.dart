import 'dart:math';

// Counts steps from raw accelerometer samples (m/s², gravity included).
//
// Walking makes the acceleration magnitude oscillate around gravity once per step.
// The detector removes gravity with a slow moving average, smooths the remaining
// signal and marks a step candidate each time it rises above [_upperThreshold], only
// after it went back below [_lowerThreshold] (hysteresis) and at least
// [_minStepInterval] after the previous candidate.
//
// Single jolts (putting the phone in the pocket, picking it up) also cross the
// threshold, so candidates only become steps once [_stepsToConfirm] of them happen in
// a steady rhythm. The confirming candidates are then counted at once, so no step of
// a real walk is lost.
class StepDetector {
  // Slow enough (~1 s at 50 Hz) to follow only gravity; a faster average followed the
  // walking oscillation itself and cancelled soft steps.
  static const _gravityAlpha = 0.98;
  static const _smoothingAlpha = 0.3;
  static const _upperThreshold = 0.6;
  static const _lowerThreshold = 0.2;
  static const _minStepInterval = Duration(milliseconds: 300);
  // A longer gap means the person stopped; the rhythm has to be confirmed again.
  static const _maxStepInterval = Duration(milliseconds: 2000);
  static const _stepsToConfirm = 4;
  // Consecutive intervals may differ by up to this factor and still count as a rhythm.
  static const _maxRhythmChange = 1.8;

  double? _gravity;
  double _smoothed = 0;
  bool _abovePeak = false;
  DateTime? _lastCandidate;
  Duration? _lastInterval;
  int _pendingSteps = 0;
  bool _walking = false;

  // Returns how many steps the sample confirmed: usually 0 or 1, or [_stepsToConfirm]
  // when a new walking rhythm is confirmed.
  int addSample(double x, double y, double z, DateTime timestamp) {
    final magnitude = sqrt(x * x + y * y + z * z);
    _gravity = _gravity == null ? magnitude : _gravityAlpha * _gravity! + (1 - _gravityAlpha) * magnitude;
    _smoothed = (1 - _smoothingAlpha) * _smoothed + _smoothingAlpha * (magnitude - _gravity!);

    if (_abovePeak) {
      if (_smoothed < _lowerThreshold) _abovePeak = false;
      return 0;
    }

    if (_smoothed <= _upperThreshold) return 0;
    if (_lastCandidate != null && timestamp.difference(_lastCandidate!) < _minStepInterval) return 0;

    _abovePeak = true;
    return _onCandidate(timestamp);
  }

  int _onCandidate(DateTime timestamp) {
    final interval = _lastCandidate == null ? null : timestamp.difference(_lastCandidate!);
    _lastCandidate = timestamp;

    if (interval == null || interval > _maxStepInterval) {
      _startSequence();
      return 0;
    }

    if (!_inRhythm(interval)) {
      // An irregular jolt; it may be the first candidate of a new rhythm.
      _startSequence();
      _lastInterval = null;
      return 0;
    }
    _lastInterval = interval;

    if (_walking) return 1;

    _pendingSteps++;
    if (_pendingSteps < _stepsToConfirm) return 0;

    _walking = true;
    final confirmed = _pendingSteps;
    _pendingSteps = 0;
    return confirmed;
  }

  bool _inRhythm(Duration interval) {
    final previous = _lastInterval;
    if (previous == null) return true;
    final ratio = interval.inMicroseconds / previous.inMicroseconds;
    return ratio <= _maxRhythmChange && ratio >= 1 / _maxRhythmChange;
  }

  // The current candidate is the first step of a possible new sequence.
  void _startSequence() {
    _walking = false;
    _pendingSteps = 1;
    _lastInterval = null;
  }

  // Called when tracking resumes so the pause doesn't affect the filters or the rhythm.
  void reset() {
    _gravity = null;
    _smoothed = 0;
    _abovePeak = false;
    _lastCandidate = null;
    _lastInterval = null;
    _pendingSteps = 0;
    _walking = false;
  }
}
