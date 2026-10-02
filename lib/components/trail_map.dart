import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Route drawn over OpenStreetMap, framed to fit the whole path.
class TrailMap extends StatelessWidget {
  final TrailRoute route;
  final double height;
  final bool interactive;

  const TrailMap({super.key, required this.route, this.height = 200, this.interactive = true});

  @override
  Widget build(BuildContext context) {
    final points = route.expand((segment) => segment).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: points.isEmpty ? _buildEmpty() : _buildMap(points),
      ),
    );
  }

  Widget _buildMap(List<LatLng> points) {
    final distinct = points.toSet();
    final cameraFit = distinct.length > 1
        ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(28), maxZoom: 17)
        : null;

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: 16,
        initialCameraFit: cameraFit,
        backgroundColor: Pallete.surfaceColor,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hiker.hiker_app',
        ),
        PolylineLayer(
          polylines: [
            for (final segment in route)
              if (segment.length > 1)
                Polyline(
                  points: segment,
                  strokeWidth: 5,
                  color: Pallete.accentColor,
                  borderStrokeWidth: 1.5,
                  borderColor: Colors.black45,
                ),
          ],
        ),
        MarkerLayer(
          markers: [
            _marker(points.first, Colors.green.shade600),
            if (distinct.length > 1) _marker(points.last, Pallete.errorColor),
          ],
        ),
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
      ],
    );
  }

  Marker _marker(LatLng point, Color color) => Marker(
        point: point,
        width: 16,
        height: 16,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Pallete.whiteColor, width: 2.5),
          ),
        ),
      );

  Widget _buildEmpty() {
    return Container(
      color: Pallete.surfaceColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_outlined, color: Pallete.whiteColor.withAlpha(120), size: 32),
          const SizedBox(height: 6),
          Text('Nenhum trajeto registrado', style: TextStyle(color: Pallete.whiteColor.withAlpha(160))),
        ],
      ),
    );
  }
}
