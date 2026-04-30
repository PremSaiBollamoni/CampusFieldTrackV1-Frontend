import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class RecentRoutesWidget extends StatefulWidget {
  const RecentRoutesWidget({super.key});

  @override
  State<RecentRoutesWidget> createState() => _RecentRoutesWidgetState();
}

class _RecentRoutesWidgetState extends State<RecentRoutesWidget>
    with SingleTickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _trackingService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _trackingService.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
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
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _trackingService.completedSessions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Sessions',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onDark,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.activityHistory),
              child: Text(
                'View all',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          _EmptySessionsCard()
        else
          ...List.generate(sessions.length, (i) {
            final session = sessions[i];
            final delay = i * 0.15;
            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(delay, delay + 0.6, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(anim),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SessionCard(
                    session: session,
                    formatDuration: _formatDuration,
                    formatDate: _formatDate,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _EmptySessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.route_rounded, size: 36, color: AppTheme.onDarkSubtle),
          const SizedBox(height: 12),
          Text(
            'No sessions yet',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a field session to see your routes here',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onDarkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrackingSession session;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;

  const _SessionCard({
    required this.session,
    required this.formatDuration,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate coverage as a percentage of route points vs max expected
    final coveragePercent = session.routePoints.isNotEmpty
        ? ((session.distanceKm / 20.0) * 100).clamp(0.0, 100.0).round()
        : 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.activityDetail,
        arguments: session,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: coveragePercent / 100,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.glassBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$coveragePercent%',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.areaName ??
                              'Session ${formatDate(session.startTime)}',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadgeWidget(
                        status: SessionStatus.completed,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(session.startTime),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.route_rounded,
                        label: '${session.distanceKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        icon: Icons.timer_rounded,
                        label: formatDuration(session.durationSeconds),
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        icon: Icons.place_rounded,
                        label: '${session.checkpoints.length} stops',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onDarkSubtle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.onDarkSubtle),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.onDarkMuted,
          ),
        ),
      ],
    );
  }
}
