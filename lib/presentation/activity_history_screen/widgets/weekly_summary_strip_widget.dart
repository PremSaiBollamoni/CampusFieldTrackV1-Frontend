import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class WeeklySummaryStripWidget extends StatelessWidget {
  final List<TrackingSession> sessions;

  const WeeklySummaryStripWidget({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = sessions
        .where(
          (s) => s.startTime.isAfter(
            DateTime(weekStart.year, weekStart.month, weekStart.day),
          ),
        )
        .toList();

    final totalKm = weekSessions.fold<double>(
      0,
      (sum, s) => sum + s.distanceKm,
    );
    final totalStops = weekSessions.fold<int>(
      0,
      (sum, s) => sum + s.checkpoints.length,
    );
    final totalSessions = weekSessions.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                _SummaryItem(
                  icon: Icons.calendar_today_rounded,
                  value: '$totalSessions',
                  label: 'Sessions',
                  color: AppTheme.primary,
                ),
                _Divider(),
                _SummaryItem(
                  icon: Icons.route_rounded,
                  value: '${totalKm.toStringAsFixed(1)} km',
                  label: 'Distance',
                  color: AppTheme.secondary,
                ),
                _Divider(),
                _SummaryItem(
                  icon: Icons.place_rounded,
                  value: '$totalStops',
                  label: 'Stops',
                  color: AppTheme.success,
                ),
                _Divider(),
                _SummaryItem(
                  icon: Icons.trending_up_rounded,
                  value: totalSessions > 0
                      ? '${(totalKm / totalSessions).toStringAsFixed(1)} km'
                      : '0.0 km',
                  label: 'Avg/Trip',
                  color: AppTheme.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.onDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppTheme.onDarkSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppTheme.glassBorder);
  }
}
