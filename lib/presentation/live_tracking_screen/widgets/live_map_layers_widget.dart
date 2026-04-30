import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/app_theme.dart';

enum TrackingState { active, paused, stopped }

class LiveMapLayersWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng currentLocation;
  final List<LatLng> routePoints;
  final List<LatLng> checkpoints;
  final Animation<double> markerPulse;
  final TrackingState trackingState;

  const LiveMapLayersWidget({
    super.key,
    required this.mapController,
    required this.currentLocation,
    required this.routePoints,
    required this.checkpoints,
    required this.markerPulse,
    required this.trackingState,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 15,
        minZoom: 10,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Light map tiles (CartoDB Positron — CORS-friendly for Flutter Web)
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.campusfieldtrack.app',
          tileProvider: NetworkTileProvider(),
        ),

        // Campus geofence boundary
        CircleLayer(
          circles: [
            CircleMarker(
              point: LatLng(28.6139, 77.2090),
              radius: 600,
              color: AppTheme.primary.withAlpha(13),
              borderColor: AppTheme.primary.withAlpha(77),
              borderStrokeWidth: 1.5,
              useRadiusInMeter: true,
            ),
          ],
        ),

        // Route polyline
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppTheme.primary,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              // Glow effect polyline
              Polyline(
                points: routePoints,
                color: AppTheme.primary.withAlpha(64),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),

        // Checkpoint markers
        MarkerLayer(
          markers: checkpoints
              .map(
                (cp) => Marker(
                  point: cp,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withAlpha(128),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Start marker
        if (routePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: routePoints.first,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withAlpha(153),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

        // Live position marker with pulse
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: markerPulse,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      if (trackingState == TrackingState.active)
                        Transform.scale(
                          scale: markerPulse.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withOpacity(
                                0.15 * (2 - markerPulse.value),
                              ),
                            ),
                          ),
                        ),
                      // Accuracy ring
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withAlpha(38),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(102),
                            width: 1,
                          ),
                        ),
                      ),
                      // Core dot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: trackingState == TrackingState.active
                              ? AppTheme.primary
                              : AppTheme.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (trackingState == TrackingState.active
                                          ? AppTheme.primary
                                          : AppTheme.warning)
                                      .withAlpha(153),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
