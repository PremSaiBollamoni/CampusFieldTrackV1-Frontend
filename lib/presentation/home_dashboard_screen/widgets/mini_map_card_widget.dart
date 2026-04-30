import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class MiniMapCardWidget extends StatefulWidget {
  final bool fullHeight;
  const MiniMapCardWidget({super.key, this.fullHeight = false});

  @override
  State<MiniMapCardWidget> createState() => _MiniMapCardWidgetState();
}

class _MiniMapCardWidgetState extends State<MiniMapCardWidget> {
  final MapController _mapController = MapController();
  final TrackingService _trackingService = TrackingService();

  @override
  void initState() {
    super.initState();
    _trackingService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _trackingService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get most recent session for map preview
    final sessions = _trackingService.completedSessions;
    final latestSession = sessions.isNotEmpty ? sessions.first : null;
    final routePoints = latestSession?.polylinePoints ?? [];
    final hasRoute = routePoints.length >= 2;

    // Center map on route or default location
    final center = hasRoute
        ? _computeCenter(routePoints)
        : const LatLng(0, 0);

    // Active session info
    final activeSession = _trackingService.activeSession;
    final isTracking = _trackingService.isTracking;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.liveTracking),
      child: Container(
        height: widget.fullHeight ? double.infinity : 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: hasRoute ? 13.5 : 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.campusfieldtrack.app',
                  ),
                  if (hasRoute)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: AppTheme.primary,
                          strokeWidth: 3.5,
                          strokeCap: StrokeCap.round,
                        ),
                      ],
                    ),
                  if (hasRoute)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints.first,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        Marker(
                          point: routePoints.last,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Active session live marker
                  if (isTracking && activeSession?.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: activeSession!.currentLocation!,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withAlpha(153),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Bottom gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xE6FFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTracking
                                  ? 'Live Session'
                                  : hasRoute
                                  ? "Last Session"
                                  : "No sessions yet",
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              isTracking
                                  ? '${(activeSession?.distanceKm ?? 0).toStringAsFixed(2)} km · Active'
                                  : hasRoute
                                  ? '${latestSession!.distanceKm.toStringAsFixed(1)} km · ${latestSession.checkpoints.length} stops'
                                  : 'Tap to start tracking',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF555577),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isTracking
                              ? AppTheme.success
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTracking
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.play_arrow_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTracking ? 'Live' : 'Track',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top label
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isTracking
                              ? AppTheme.success
                              : AppTheme.onDarkSubtle,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isTracking ? 'Live' : 'Map',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng _computeCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}
