import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class HeroStatsWidget extends StatefulWidget {
  const HeroStatsWidget({super.key});

  @override
  State<HeroStatsWidget> createState() => _HeroStatsWidgetState();
}

class _HeroStatsWidgetState extends State<HeroStatsWidget>
    with SingleTickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  late AnimationController _controller;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anims = List.generate(
      3,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    _trackingService.addListener(_onUpdate);
    _trackingService.initialize();
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

  @override
  Widget build(BuildContext context) {
    final distanceKm = _trackingService.todayDistanceKm;
    final durationSec = _trackingService.todayDurationSeconds;
    final stops = _trackingService.todayStops;
    final sessions = _trackingService.completedSessions;

    // Compare with yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayDist = sessions
        .where(
          (s) =>
              s.startTime.year == yesterday.year &&
              s.startTime.month == yesterday.month &&
              s.startTime.day == yesterday.day,
        )
        .fold(0.0, (sum, s) => sum + s.distanceKm);

    final distDiff = distanceKm - yesterdayDist;
    final distTrend = distDiff >= 0
        ? '+${distDiff.toStringAsFixed(1)} km vs yesterday'
        : '${distDiff.toStringAsFixed(1)} km vs yesterday';

    final statsMaps = [
      {
        'label': 'Distance Today',
        'value': distanceKm > 0 ? distanceKm.toStringAsFixed(1) : '0.0',
        'unit': 'km',
        'icon': Icons.route_rounded,
        'color': 0xFF3B82F6,
        'trend': sessions.isEmpty ? 'No sessions yet' : distTrend,
        'trendUp': distDiff >= 0,
      },
      {
        'label': 'Time in Field',
        'value': durationSec > 0 ? _formatDuration(durationSec) : '0m',
        'unit': '',
        'icon': Icons.timer_rounded,
        'color': 0xFF06B6D4,
        'trend': sessions.isEmpty
            ? 'Start a session'
            : '${sessions.where((s) {
                final t = DateTime.now();
                return s.startTime.year == t.year && s.startTime.month == t.month && s.startTime.day == t.day;
              }).length} session(s) today',
        'trendUp': durationSec > 0,
      },
      {
        'label': 'Stops Today',
        'value': stops > 0 ? '$stops' : '0',
        'unit': 'visits',
        'icon': Icons.place_rounded,
        'color': 0xFF10B981,
        'trend': sessions.isEmpty ? 'No visits yet' : '$stops checkpoints',
        'trendUp': stops > 0,
      },
    ];

    return Row(
      children: List.generate(statsMaps.length, (i) {
        final stat = statsMaps[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == statsMaps.length - 1 ? 0 : 6,
            ),
            child: FadeTransition(
              opacity: _anims[i],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_anims[i]),
                child: _StatCard(stat: stat),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = Color(stat['color'] as int);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  stat['value'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onDark,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((stat['unit'] as String).isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    stat['unit'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onDarkMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat['label'] as String,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.onDarkMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                (stat['trendUp'] as bool)
                    ? Icons.trending_up_rounded
                    : Icons.info_outline_rounded,
                size: 10,
                color: (stat['trendUp'] as bool)
                    ? AppTheme.success
                    : AppTheme.onDarkSubtle,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  stat['trend'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: (stat['trendUp'] as bool)
                        ? AppTheme.success
                        : AppTheme.onDarkSubtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
