import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/utils/trail_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('formats dates like the prototype', () {
    expect(formatTrailDate(DateTime(2026, 5, 9)), '9, mai, 26');
    expect(formatTrailDate(DateTime(2026, 9, 10)), '10, set, 26');
  });

  test('formats kilometers', () {
    expect(formatKm(0), '0');
    expect(formatKm(700), '0.7');
    expect(formatKm(5000), '5');
    expect(formatKm(5340), '5.3');
    expect(formatKm(11200), '11');
  });

  test('formats durations', () {
    expect(formatDuration(const Duration(minutes: 4, seconds: 5)), '04:05');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  test('route survives the JSON round trip', () {
    final route = [
      [const LatLng(-23.1, -46.9), const LatLng(-23.2, -46.8)],
      [const LatLng(-23.3, -46.7)],
    ];
    expect(parseRoute(routeToJson(route)), route);
  });
}
