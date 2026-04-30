import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../routes/app_routes.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_theme.dart';
import './widgets/tracking_controls_widget.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  final MapController _mapController = MapController();

  late AnimationController _markerPulseController;
  late AnimationController _controlsEntranceController;
  late Animation<double> _markerPulse;
  late Animation<double> _controlsEntrance;

  final bool _isBottomSheetExpanded = false;
  bool _mapFollowsUser = true;
  bool _isInitializing = true;
  Timer? _durationTimer;
  int _displayDurationSeconds = 0;
  LatLng? _currentDeviceLocation; // Real GPS location even before tracking
  LatLng? _lastCameraPosition; // Track last camera position to avoid jitter
  double _lastSpeed = 0.0; // Track speed for dynamic threshold

  // --- Batch map updates: debounce setState to at most once per 500 ms ---
  Timer? _uiDebounceTimer;
  static const Duration _uiDebounceDuration = Duration(milliseconds: 500);

  // Cache rendered polyline to avoid rebuilding when nothing changed
  List<LatLng> _renderedPolyline = [];

  @override
  void initState() {
    super.initState();

    _markerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _markerPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _markerPulseController, curve: Curves.easeInOut),
    );

    _controlsEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _controlsEntrance = CurvedAnimation(
      parent: _controlsEntranceController,
      curve: Curves.easeOutCubic,
    );

    _trackingService.addListener(_onTrackingUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    await _trackingService.initialize();

    // Fetch real device location immediately on screen open
    await _fetchCurrentLocation();

    setState(() => _isInitializing = false);

    // If there's a restored paused session, show recovery dialog
    if (_trackingService.activeSession != null &&
        _trackingService.trackingState == TrackingState.paused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSessionRecoveryDialog();
      });
    }
  }

  /// Fetches the real GPS location and centers the map on it.
  Future<void> _fetchCurrentLocation() async {
    if (!_trackingService.permissionGranted) {
      final granted = await _trackingService.requestPermissions();
      if (!granted) return;
    }
    if (!_trackingService.gpsAvailable) return;

    try {
      // Use a relaxed accuracy first for fast fix, then refine
      Position pos =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          ).catchError((_) async {
            return await Geolocator.getLastKnownPosition() ??
                Position(
                  latitude: 0,
                  longitude: 0,
                  timestamp: DateTime.now(),
                  accuracy: 999,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                );
          });

      // If we got a valid fix (not the fallback zeros)
      if (pos.accuracy < 999 && (pos.latitude != 0 || pos.longitude != 0)) {
        final loc = LatLng(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() => _currentDeviceLocation = loc);
          try {
            _mapController.move(loc, 17.0);
          } catch (_) {}
        }

        // Try to get a more accurate fix in the background
        Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 20),
              ),
            )
            .then((highAccPos) {
              if (mounted && highAccPos.accuracy < 100) {
                final highLoc = LatLng(
                  highAccPos.latitude,
                  highAccPos.longitude,
                );
                setState(() => _currentDeviceLocation = highLoc);
                if (_mapFollowsUser &&
                    _trackingService.trackingState == TrackingState.idle) {
                  try {
                    _mapController.move(highLoc, 17.0);
                  } catch (_) {}
                }
              }
            })
            .catchError((_) {});
      }
    } catch (_) {}
  }

  void _onTrackingUpdate() {
    if (!mounted) return;

    // Always keep duration counter in sync immediately (cheap int update)
    _displayDurationSeconds =
        _trackingService.activeSession?.durationSeconds ?? 0;

    // Immediately sync polyline from real geolocator data
    final newPoints = _trackingService.activeSession?.polylinePoints ?? [];
    _renderedPolyline = List<LatLng>.from(newPoints);

    // Sync device location and smoothly follow user during active tracking
    if (_mapFollowsUser && _trackingService.isTracking) {
      final loc = _trackingService.activeSession?.currentLocation;
      final speed = _trackingService.activeSession?.currentSpeedKmh ?? 0.0;
      
      if (loc != null) {
        _currentDeviceLocation = loc;
        _lastSpeed = speed;
        
        // Dynamic threshold based on speed
        double threshold;
        if (speed < 3.0) {
          threshold = 0.005; // ~5m for walking
        } else if (speed < 8.0) {
          threshold = 0.008; // ~8m for jogging
        } else {
          threshold = 0.012; // ~12m for running/cycling
        }

        // Only move camera if user moved significantly
        bool shouldMoveCamera = false;
        if (_lastCameraPosition == null) {
          shouldMoveCamera = true;
        } else {
          final distance = _calculateDistance(
            _lastCameraPosition!.latitude,
            _lastCameraPosition!.longitude,
            loc.latitude,
            loc.longitude,
          );
          shouldMoveCamera = distance > threshold;
        }

        if (shouldMoveCamera) {
          try {
            // Calculate forward offset target (user at 65% height)
            final offsetTarget = _calculateOffsetTarget(loc, newPoints);
            _mapController.move(offsetTarget, 17.0);
            _lastCameraPosition = loc;
          } catch (_) {}
        }
      }
    }

    // Debounce full setState to batch rapid GPS callbacks into one frame
    _uiDebounceTimer?.cancel();
    _uiDebounceTimer = Timer(_uiDebounceDuration, () {
      if (!mounted) return;
      setState(() {
        _renderedPolyline = List<LatLng>.from(
          _trackingService.activeSession?.polylinePoints ?? [],
        );
        _displayDurationSeconds =
            _trackingService.activeSession?.durationSeconds ?? 0;
      });
    });
  }

  // Calculate target with forward offset (user at 65% screen height)
  LatLng _calculateOffsetTarget(LatLng userLoc, List<LatLng> points) {
    if (points.length < 2) return userLoc;

    // Get bearing from last 2 points
    final p1 = points[points.length - 2];
    final p2 = points.last;
    final bearing = _calculateBearing(p1.latitude, p1.longitude, p2.latitude, p2.longitude);

    // Offset distance: ~80m ahead in movement direction
    const offsetKm = 0.08;
    final offsetLat = offsetKm * cos(_toRadians(bearing)) / 111.32;
    final offsetLng = offsetKm * sin(_toRadians(bearing)) / (111.32 * cos(_toRadians(userLoc.latitude)));

    return LatLng(
      userLoc.latitude - offsetLat, // Negative to show path ahead
      userLoc.longitude - offsetLng,
    );
  }

  // Calculate bearing between two points
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);
    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  // Calculate distance between two points in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_trackingService.isTracking && mounted) {
        setState(() {
          _displayDurationSeconds =
              _trackingService.activeSession?.durationSeconds ?? 0;
        });
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
  }

  Future<void> _onStartTracking() async {
    if (!_trackingService.permissionGranted) {
      final granted = await _trackingService.requestPermissions();
      if (!granted) {
        _showPermissionDialog();
        return;
      }
    }

    if (!_trackingService.gpsAvailable) {
      _showGpsDisabledDialog();
      return;
    }

    await _trackingService.startTracking();
    _startDurationTimer();
    setState(() => _mapFollowsUser = true);

    // Center map on current location with close zoom when tracking starts
    final loc = _currentDeviceLocation;
    if (loc != null) {
      try {
        _mapController.move(loc, 17.0);
        _lastCameraPosition = loc;
      } catch (_) {}
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final newLoc = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentDeviceLocation = newLoc);
        _mapController.move(newLoc, 17.0);
        _lastCameraPosition = newLoc;
      } catch (_) {}
    }
  }

  void _onPauseTracking() {
    _trackingService.pauseTracking();
    _stopDurationTimer();
  }

  void _onResumeTracking() {
    _trackingService.resumeTracking();
    _startDurationTimer();
  }

  Future<void> _onStopTracking() async {
    _stopDurationTimer();
    // Record current location as a final stop point before ending the session
    final currentLoc = _trackingService.activeSession?.currentLocation;
    if (currentLoc != null) {
      _trackingService.recordManualCheckpoint(currentLoc);
    }
    final session = await _trackingService.stopTracking();
    
    // Fit map to show entire route after stopping
    if (session != null && mounted) {
      final points = session.polylinePoints;
      if (points.length >= 2) {
        try {
          _fitMapToRoute(points);
        } catch (_) {}
      }
      _showSessionSummarySheet(session);
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {}
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Location Permission Required',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        content: Text(
          'Campus FieldTrack needs location access to track your field sessions. Please grant location permission in Settings.',
          style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _trackingService.openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'GPS Disabled',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        content: Text(
          'Please enable GPS/Location Services on your device to start tracking.',
          style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _trackingService.openLocationSettings();
            },
            child: Text(
              'Enable GPS',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionRecoveryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Session Recovered',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        content: Text(
          'A previous tracking session was found. Would you like to resume it?',
          style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _trackingService.discardSession();
            },
            child: Text(
              'Discard',
              style: GoogleFonts.manrope(color: AppTheme.error),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onResumeTracking();
            },
            child: Text(
              'Resume',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave Tracking?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        content: Text(
          'Tracking will continue in the background. Your session will be saved.',
          style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Stay',
              style: GoogleFonts.manrope(color: AppTheme.onDarkMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.homeDashboard);
            },
            child: Text(
              'Leave',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionSummarySheet(TrackingSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SessionSummarySheet(
        session: session,
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.activityHistory);
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _trackingService.removeListener(_onTrackingUpdate);
    _markerPulseController.dispose();
    _controlsEntranceController.dispose();
    _durationTimer?.cancel();
    _uiDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _trackingService.activeSession;
    final trackingState = _trackingService.trackingState;
    final routePoints = session?.polylinePoints ?? [];
    final checkpoints =
        session?.checkpoints.map((c) => c.location).toList() ?? [];

    // Priority: active session location > fetched device location > null (no marker)
    final LatLng? resolvedLocation =
        session?.currentLocation ?? _currentDeviceLocation;

    // Only use a default center if we have absolutely no location yet
    final LatLng mapCenter =
        resolvedLocation ??
        const LatLng(20.5937, 78.9629); // India center as fallback

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: Stack(
        children: [
          // Full-screen map
          _buildMap(
            mapCenter,
            resolvedLocation,
            routePoints,
            checkpoints,
            trackingState,
          ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCCF1F5F9), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xF0F1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      if (trackingState == TrackingState.active ||
                          trackingState == TrackingState.paused) {
                        _showExitConfirmDialog();
                      } else {
                        Navigator.pushNamed(context, AppRoutes.homeDashboard);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatusBadge(trackingState)),
                  if (!_mapFollowsUser && _trackingService.isTracking)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _RecenterButton(
                        onTap: () {
                          setState(() => _mapFollowsUser = true);
                          final loc = resolvedLocation ?? mapCenter;
                          _mapController.move(loc, 17.0);
                          _lastCameraPosition = _currentDeviceLocation;
                        },
                      ),
                    ),
                  _GlassButton(
                    icon: _mapFollowsUser
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    onTap: () {
                      setState(() => _mapFollowsUser = !_mapFollowsUser);
                      if (_mapFollowsUser) {
                        _mapController.move(
                          resolvedLocation ?? mapCenter,
                          17.0,
                        );
                        _lastCameraPosition = _currentDeviceLocation;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // GPS error banner
          if (_trackingService.locationError != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: SafeArea(
                child: _ErrorBanner(message: _trackingService.locationError!),
              ),
            ),

          // Stat chips
          if (trackingState == TrackingState.active ||
              trackingState == TrackingState.paused)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: GlassStatChipWidget(
                        icon: Icons.route_rounded,
                        label: 'Distance',
                        value:
                            '${(session?.distanceKm ?? 0).toStringAsFixed(2)} km',
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassStatChipWidget(
                        icon: Icons.timer_rounded,
                        label: 'Duration',
                        value: _formatDuration(_displayDurationSeconds),
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassStatChipWidget(
                        icon: Icons.place_rounded,
                        label: 'Stops',
                        value: '${session?.checkpoints.length ?? 0}',
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassStatChipWidget(
                        icon: Icons.speed_rounded,
                        label: 'Speed',
                        value:
                            '${(session?.currentSpeedKmh ?? 0).toStringAsFixed(1)} km/h',
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: FadeTransition(
                opacity: _controlsEntrance,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isInitializing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Acquiring GPS...',
                          style: GoogleFonts.manrope(
                            color: AppTheme.onDarkMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    TrackingControlsWidget(
                      trackingState: trackingState,
                      onStart: _onStartTracking,
                      onPause: _onPauseTracking,
                      onResume: _onResumeTracking,
                      onStop: _onStopTracking,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    LatLng mapCenter,
    LatLng? userLocation,
    List<LatLng> routePoints,
    List<LatLng> checkpoints,
    TrackingState trackingState,
  ) {
    // Always use the latest polyline from geolocator data
    final displayPolyline = _renderedPolyline.isNotEmpty
        ? _renderedPolyline
        : routePoints;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 17.0,
        minZoom: 10,
        maxZoom: 19,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture && _mapFollowsUser) {
            setState(() => _mapFollowsUser = false);
          }
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.campusfieldtrack.app',
          tileProvider: NetworkTileProvider(),
        ),

        // Route polyline with glow
        if (displayPolyline.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: displayPolyline,
                color: AppTheme.primary.withAlpha(64),
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
              ),
              Polyline(
                points: displayPolyline,
                color: AppTheme.primary,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // Start marker
        if (displayPolyline.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: displayPolyline.first,
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
                        spreadRadius: 2,
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
            ],
          ),

        // Checkpoint markers — batched into a single MarkerLayer
        if (checkpoints.isNotEmpty)
          MarkerLayer(
            markers: checkpoints
                .map(
                  (cp) => Marker(
                    point: cp,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warning.withAlpha(128),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pause_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

        // Live user location marker — only shown when we have a real location
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation,
                width: 64,
                height: 64,
                child: AnimatedBuilder(
                  animation: _markerPulse,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (trackingState == TrackingState.active)
                          Transform.scale(
                            scale: _markerPulse.value,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(
                                  0.12 * (2 - _markerPulse.value),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withAlpha(38),
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(102),
                              width: 1,
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: trackingState == TrackingState.active
                                ? AppTheme.primary
                                : trackingState == TrackingState.paused
                                ? AppTheme.warning
                                : AppTheme.onDarkSubtle,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (trackingState == TrackingState.active
                                            ? AppTheme.primary
                                            : AppTheme.warning)
                                        .withAlpha(153),
                                blurRadius: 12,
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

  Widget _buildStatusBadge(TrackingState state) {
    Color color;
    String label;
    IconData icon;

    switch (state) {
      case TrackingState.active:
        color = AppTheme.success;
        label = 'LIVE TRACKING';
        icon = Icons.radio_button_checked_rounded;
        break;
      case TrackingState.paused:
        color = AppTheme.warning;
        label = 'PAUSED';
        icon = Icons.pause_circle_rounded;
        break;
      case TrackingState.stopped:
        color = AppTheme.error;
        label = 'STOPPED';
        icon = Icons.stop_circle_rounded;
        break;
      default:
        color = AppTheme.onDarkSubtle;
        label = 'READY';
        icon = Icons.location_on_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Icon(icon, color: AppTheme.onDark, size: 20),
          ),
        ),
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withAlpha(77)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'RECENTER',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withAlpha(38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withAlpha(77)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassStatChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const GlassStatChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onDark,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  color: AppTheme.onDarkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSummarySheet extends StatelessWidget {
  final TrackingSession session;
  final VoidCallback onDone;

  const _SessionSummarySheet({required this.session, required this.onDone});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Session Complete!',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your session has been saved',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onDarkMuted,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _SummaryStatTile(
                icon: Icons.route_rounded,
                label: 'Distance',
                value: '${session.distanceKm.toStringAsFixed(2)} km',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _SummaryStatTile(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: _formatDuration(session.durationSeconds),
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              _SummaryStatTile(
                icon: Icons.place_rounded,
                label: 'Stops',
                value: '${session.checkpoints.length}',
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onDone,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(102),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'View History',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.onDark,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: AppTheme.onDarkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
