import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class WeeklyChartWidget extends StatefulWidget {
  const WeeklyChartWidget({super.key});

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget>
    with SingleTickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  int _touchedIndex = -1;
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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

  List<Map<String, dynamic>> _buildWeeklyData() {
    final now = DateTime.now();
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKm = _trackingService.completedSessions
          .where(
            (s) =>
                s.startTime.year == day.year &&
                s.startTime.month == day.month &&
                s.startTime.day == day.day,
          )
          .fold(0.0, (sum, s) => sum + s.distanceKm);

      result.add({
        'day': days[day.weekday - 1],
        'km': dayKm,
        'isToday': i == 0,
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyData = _buildWeeklyData();
    final totalWeekly = weeklyData.fold(
      0.0,
      (sum, d) => sum + (d['km'] as double),
    );
    final maxKm = weeklyData
        .map((d) => d['km'] as double)
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxKm < 5 ? 10.0 : (maxKm * 1.3).ceilToDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Coverage',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalWeekly > 0
                              ? '${totalWeekly.toStringAsFixed(1)} km this week'
                              : 'No sessions this week',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.onDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'This Week',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return SizedBox(
                    height: 140,
                    child: BarChart(
                      BarChartData(
                        maxY: chartMax,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            setState(() {
                              _touchedIndex =
                                  response?.spot?.touchedBarGroupIndex ?? -1;
                            });
                          },
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: AppTheme.surfaceElevated,
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(1)} km',
                                GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onDark,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= weeklyData.length) {
                                  return const SizedBox.shrink();
                                }
                                final isToday =
                                    weeklyData[idx]['isToday'] as bool;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    weeklyData[idx]['day'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isToday
                                          ? AppTheme.primary
                                          : AppTheme.onDarkSubtle,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: chartMax / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppTheme.glassBorder,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(weeklyData.length, (i) {
                          final data = weeklyData[i];
                          final isToday = data['isToday'] as bool;
                          final isTouched = _touchedIndex == i;
                          final km = (data['km'] as double) * _anim.value;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: km,
                                width: 18,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                gradient: LinearGradient(
                                  colors: isToday
                                      ? [AppTheme.primary, AppTheme.secondary]
                                      : isTouched
                                      ? [
                                          AppTheme.primary.withAlpha(179),
                                          AppTheme.primary.withAlpha(102),
                                        ]
                                      : [
                                          AppTheme.surfaceElevated,
                                          AppTheme.surfaceVariant,
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
