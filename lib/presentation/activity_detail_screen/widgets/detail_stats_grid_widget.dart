import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class DetailStatsGridWidget extends StatelessWidget {
  final TrackingSession session;

  const DetailStatsGridWidget({super.key, required this.session});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final coveragePercent = ((session.distanceKm / 20.0) * 100)
        .clamp(0.0, 100.0)
        .round();

    final stats = [
      {
        'label': 'Distance',
        'value': '${session.distanceKm.toStringAsFixed(2)} km',
        'icon': Icons.route_rounded,
        'color': AppTheme.primary,
      },
      {
        'label': 'Duration',
        'value': _formatDuration(session.durationSeconds),
        'icon': Icons.timer_rounded,
        'color': AppTheme.secondary,
      },
      {
        'label': 'Stops',
        'value': '${session.checkpoints.length} visits',
        'icon': Icons.place_rounded,
        'color': AppTheme.success,
      },
      {
        'label': 'Avg Speed',
        'value': '${session.avgSpeedKmh.toStringAsFixed(1)} km/h',
        'icon': Icons.speed_rounded,
        'color': AppTheme.warning,
      },
      {
        'label': 'Coverage',
        'value': '$coveragePercent%',
        'icon': Icons.map_rounded,
        'color': const Color(0xFFA855F7),
      },
      {
        'label': 'Pace',
        'value': session.durationSeconds > 0 && session.distanceKm > 0
            ? '${(session.durationSeconds / 60 / session.distanceKm).toStringAsFixed(1)} min/km'
            : '—',
        'icon': Icons.directions_walk_rounded,
        'color': const Color(0xFFEC4899),
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat['icon'] as IconData, size: 16, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['value'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onDark,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stat['label'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: AppTheme.onDarkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
