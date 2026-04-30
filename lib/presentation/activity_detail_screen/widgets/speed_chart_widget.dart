import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class SpeedChartWidget extends StatelessWidget {
  final List<RoutePoint> routePoints;
  final int durationSeconds;

  const SpeedChartWidget({
    super.key,
    required this.routePoints,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // Build real speed profile from route points
    List<FlSpot> speedPoints = [];

    if (routePoints.isNotEmpty) {
      // Sample up to 20 points evenly
      final step = (routePoints.length / 20).ceil().clamp(
        1,
        routePoints.length,
      );
      for (int i = 0; i < routePoints.length; i += step) {
        final point = routePoints[i];
        final x = i.toDouble();
        final speedKmh = (point.speed * 3.6).clamp(0.0, 30.0);
        speedPoints.add(FlSpot(x, speedKmh));
      }
    }

    // Fallback if no real data
    if (speedPoints.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed Profile',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'km/h throughout the session',
            style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onDarkMuted),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Center(
              child: Text(
                'No speed data available',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onDarkMuted,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final maxSpeed = speedPoints
        .map((s) => s.y)
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxSpeed < 5 ? 10.0 : (maxSpeed * 1.2).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speed Profile',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'km/h throughout the session',
          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onDarkMuted),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: chartMax,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.glassBorder,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: chartMax / 4,
                          reservedSize: 30,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              color: AppTheme.onDarkSubtle,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: speedPoints.length / 4,
                          getTitlesWidget: (v, _) {
                            if (speedPoints.isEmpty) return const SizedBox();
                            final idx = v.toInt().clamp(
                              0,
                              speedPoints.length - 1,
                            );
                            final timeFrac = idx / speedPoints.length;
                            final mins = (timeFrac * durationSeconds / 60)
                                .round();
                            return Text(
                              '${mins}m',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                color: AppTheme.onDarkSubtle,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: speedPoints,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppTheme.secondary,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) {
                            if (spot.y < 0.5) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: AppTheme.warning,
                                strokeColor: Colors.white,
                                strokeWidth: 1.5,
                              );
                            }
                            return FlDotCirclePainter(
                              radius: 0,
                              color: Colors.transparent,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondary.withAlpha(64),
                              AppTheme.secondary.withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: AppTheme.surfaceElevated,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (spots) => spots.map((s) {
                          return LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} km/h',
                            GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
