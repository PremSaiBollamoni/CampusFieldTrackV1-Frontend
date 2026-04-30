import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/export_service.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_theme.dart';
import './widgets/checkpoint_timeline_widget.dart';
import './widgets/detail_stats_grid_widget.dart';
import './widgets/export_actions_widget.dart';
import './widgets/speed_chart_widget.dart';

class ActivityDetailScreen extends StatefulWidget {
  final dynamic sessionData; // TrackingSession or Map<String,dynamic>

  const ActivityDetailScreen({super.key, this.sessionData});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _replayController;
  late Animation<double> _entranceAnim;

  bool _isReplaying = false;
  int _replayPointIndex = 0;
  Timer? _replayTimer;
  List<LatLng> _replayPoints = [];
  final MapController _mapController = MapController();

  TrackingSession? _session;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _replayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Accept TrackingSession directly or look up from service
    if (widget.sessionData is TrackingSession) {
      _session = widget.sessionData as TrackingSession;
      print('✅ Session loaded directly: ${_session!.id}');
    } else if (widget.sessionData is Map<String, dynamic>) {
      // Legacy path - try to find session by id
      final id = (widget.sessionData as Map<String, dynamic>)['id'] as String?;
      print('🔍 Looking up session by ID: $id');
      if (id != null) {
        _session = TrackingService().completedSessions
            .where((s) => s.id == id)
            .firstOrNull;
        if (_session != null) {
          print('✅ Session found: ${_session!.id}');
        } else {
          print('❌ Session not found in TrackingService');
        }
      }
    } else {
      print('❌ Invalid sessionData type: ${widget.sessionData.runtimeType}');
    }

    if (_session != null) {
      _replayPoints = List.from(_session!.polylinePoints);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _replayController.dispose();
    _replayTimer?.cancel();
    super.dispose();
  }

  void _startReplay() {
    if (_session == null || _session!.routePoints.isEmpty) return;
    final fullRoute = _session!.polylinePoints;
    setState(() {
      _isReplaying = true;
      _replayPointIndex = 0;
      _replayPoints = [fullRoute.first];
    });

    _replayTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_replayPointIndex < fullRoute.length - 1) {
        _replayPointIndex++;
        setState(() {
          _replayPoints = fullRoute.sublist(0, _replayPointIndex + 1);
        });
        try {
          _mapController.move(
            fullRoute[_replayPointIndex],
            _mapController.camera.zoom,
          );
        } catch (_) {}
      } else {
        timer.cancel();
        setState(() => _isReplaying = false);
      }
    });
  }

  void _stopReplay() {
    _replayTimer?.cancel();
    setState(() {
      _isReplaying = false;
      _replayPoints = _session != null
          ? List.from(_session!.polylinePoints)
          : [];
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppTheme.onDarkSubtle,
              ),
              const SizedBox(height: 16),
              Text(
                'Session not found',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: AppTheme.onDarkMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.manrope(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
    );
  }

  Widget _buildPhoneLayout() {
    final session = _session!;
    final fullRoute = session.polylinePoints;
    final checkpointMarkers = session.checkpoints
        .map(
          (c) => {
            'lat': c.location.latitude,
            'lng': c.location.longitude,
            'arrivedAt': c.arrivedAt.toIso8601String(),
            'duration': _formatDuration(c.duration.inSeconds),
            'index': c.index,
          },
        )
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _GlassCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _GlassCircleButton(
                icon: Icons.ios_share_rounded,
                onTap: () => _showExportSheet(context),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildDetailMap(fullRoute, checkpointMarkers),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _entranceAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSessionHeader(session),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DetailStatsGridWidget(session: session),
                ),
                const SizedBox(height: 20),
                _buildReplayControl(fullRoute),
                const SizedBox(height: 20),
                if (checkpointMarkers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CheckpointTimelineWidget(
                      checkpoints: checkpointMarkers,
                    ),
                  ),
                if (checkpointMarkers.isNotEmpty) const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SpeedChartWidget(
                    routePoints: session.routePoints,
                    durationSeconds: session.durationSeconds,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ExportActionsWidget(session: session),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final session = _session!;
    final fullRoute = session.polylinePoints;
    final checkpointMarkers = session.checkpoints
        .map(
          (c) => {
            'lat': c.location.latitude,
            'lng': c.location.longitude,
            'arrivedAt': c.arrivedAt.toIso8601String(),
            'duration': _formatDuration(c.duration.inSeconds),
            'index': c.index,
          },
        )
        .toList();

    return SafeArea(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                _buildDetailMap(fullRoute, checkpointMarkers),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _GlassCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionHeader(session),
                  const SizedBox(height: 20),
                  DetailStatsGridWidget(session: session),
                  const SizedBox(height: 16),
                  _buildReplayControl(fullRoute),
                  const SizedBox(height: 16),
                  if (checkpointMarkers.isNotEmpty)
                    CheckpointTimelineWidget(checkpoints: checkpointMarkers),
                  if (checkpointMarkers.isNotEmpty) const SizedBox(height: 16),
                  SpeedChartWidget(
                    routePoints: session.routePoints,
                    durationSeconds: session.durationSeconds,
                  ),
                  const SizedBox(height: 16),
                  ExportActionsWidget(session: session),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMap(
    List<LatLng> fullRoute,
    List<Map<String, dynamic>> checkpoints,
  ) {
    final center = fullRoute.isNotEmpty
        ? _computeCenter(fullRoute)
        : const LatLng(28.6139, 77.2090);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
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
          tileProvider: NetworkTileProvider(),
        ),
        // Full route (dimmed)
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
        // Replay route
        if (_replayPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _replayPoints,
                color: AppTheme.primary,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              Polyline(
                points: _replayPoints,
                color: AppTheme.primary.withAlpha(64),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),
        // Start marker
        if (fullRoute.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: fullRoute.first,
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
                        blurRadius: 10,
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
        // End marker
        if (fullRoute.length >= 2)
          MarkerLayer(
            markers: [
              Marker(
                point: fullRoute.last,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withAlpha(153),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        // Checkpoint markers
        MarkerLayer(
          markers: checkpoints
              .map(
                (cp) => Marker(
                  point: LatLng(
                    (cp['lat'] as num).toDouble(),
                    (cp['lng'] as num).toDouble(),
                  ),
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warning.withAlpha(128),
                          blurRadius: 6,
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
        // Replay head marker
        if (_isReplaying && _replayPoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: _replayPoints.last,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(153),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSessionHeader(TrackingSession session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.areaName ?? 'Field Session',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.onDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppTheme.onDarkSubtle,
              ),
              const SizedBox(width: 5),
              Text(
                _formatDate(session.startTime),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onDarkMuted,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppTheme.onDarkSubtle,
              ),
              const SizedBox(width: 5),
              Text(
                '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onDarkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplayControl(List<LatLng> fullRoute) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _isReplaying ? _stopReplay : _startReplay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: _isReplaying
                ? LinearGradient(
                    colors: [
                      AppTheme.error.withAlpha(51),
                      AppTheme.error.withAlpha(26),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0x303B82F6), Color(0x203B82F6)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isReplaying
                  ? AppTheme.error.withAlpha(102)
                  : AppTheme.primary.withAlpha(102),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isReplaying
                      ? AppTheme.error.withAlpha(51)
                      : AppTheme.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isReplaying ? Icons.stop_rounded : Icons.play_circle_rounded,
                  color: _isReplaying ? AppTheme.error : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isReplaying ? 'Replaying Route...' : 'Replay Route',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onDark,
                      ),
                    ),
                    Text(
                      _isReplaying
                          ? 'Tap to stop replay'
                          : 'Watch your journey on the map',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isReplaying && fullRoute.isNotEmpty)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                    value: _replayPointIndex / (fullRoute.length - 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Session',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ExportBtn(
                    icon: Icons.map_rounded,
                    label: 'GPX',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      ExportService().exportAndShare(context, _session!, 'GPX');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExportBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'CSV',
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.pop(ctx);
                      ExportService().exportAndShare(context, _session!, 'CSV');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExportBtn(
                    icon: Icons.data_object_rounded,
                    label: 'JSON',
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.pop(ctx);
                      ExportService().exportAndShare(
                        context,
                        _session!,
                        'JSON',
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  LatLng _computeCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(28.6139, 77.2090);
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}

class _ExportBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(64)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.onDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
