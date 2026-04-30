import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/app_theme.dart';

class DetailMapWidget extends StatelessWidget {
  final List<LatLng> fullRoute;
  final List<LatLng> replayPoints;
  final List<Map<String, dynamic>> checkpointMaps;
  final MapController mapController;

  const DetailMapWidget({
    super.key,
    required this.fullRoute,
    required this.replayPoints,
    required this.checkpointMaps,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final center = fullRoute.isNotEmpty
        ? LatLng(
            fullRoute.map((p) => p.latitude).reduce((a, b) => a + b) /
                fullRoute.length,
            fullRoute.map((p) => p.longitude).reduce((a, b) => a + b) /
                fullRoute.length,
          )
        : LatLng(28.6200, 77.2080);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.campusfieldtrack.app',
        ),

        // Ghost full route (faded)
        if (fullRoute.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: fullRoute,
                color: AppTheme.primary.withAlpha(51),
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),

        // Active replay route
        if (replayPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: replayPoints,
                color: AppTheme.primary,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              Polyline(
                points: replayPoints,
                color: AppTheme.primary.withAlpha(64),
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),

        // Checkpoint markers
        MarkerLayer(
          markers: checkpointMaps.map((cp) {
            return Marker(
              point: LatLng(cp['lat'] as double, cp['lng'] as double),
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withAlpha(128),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${(cp['index'] as int) + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Start marker
        if (fullRoute.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: fullRoute.first,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withAlpha(153),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              Marker(
                point: fullRoute.last,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withAlpha(153),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
