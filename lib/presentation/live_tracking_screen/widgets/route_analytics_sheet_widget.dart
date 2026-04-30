import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

enum TrackingState { idle, tracking, paused, stopped }

class RouteAnalyticsSheetWidget extends StatelessWidget {
  final TrackingState trackingState;
  final double distanceKm;
  final int durationSeconds;
  final int stops;
  final double speedKmh;
  final List<LatLng> routePoints;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final Widget child;

  const RouteAnalyticsSheetWidget({
    super.key,
    required this.trackingState,
    required this.distanceKm,
    required this.durationSeconds,
    required this.stops,
    required this.speedKmh,
    required this.routePoints,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: const Color(0xEEFFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(
              top: BorderSide(color: AppTheme.glassBorder, width: 1),
              left: BorderSide(color: AppTheme.glassBorder, width: 1),
              right: BorderSide(color: AppTheme.glassBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              GestureDetector(
                onTap: onExpandToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.onDarkSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls
              child,

              // Expanded analytics
              if (isExpanded) ...[
                const Divider(color: AppTheme.glassBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Route Analytics',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSpeedChart(),
                      const SizedBox(height: 16),
                      _buildRouteStats(),
                    ],
                  ),
                ),
              ],

              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedChart() {
    // Build real speed data from route points
    List<FlSpot> speedData = [];
    
    if (routePoints.isNotEmpty) {
      final step = (routePoints.length / 10).ceil().clamp(1, routePoints.length);
      for (int i = 0; i < routePoints.length; i += step) {
        speedData.add(FlSpot(speedData.length.toDouble(), speedKmh));
      }
    }
    
    // Show empty if no data
    if (speedData.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No speed data yet',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onDarkMuted,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 15,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 5,
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
                interval: 5,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    color: AppTheme.onDarkSubtle,
                  ),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
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
              spots: speedData,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha(51),
                    AppTheme.primary.withAlpha(0),
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
    );
  }

  Widget _buildRouteStats() {
    return Row(
      children: [
        Expanded(
          child: _AnalyticTile(
            label: 'Avg Speed',
            value: durationSeconds > 0
                ? '${(distanceKm / (durationSeconds / 3600)).toStringAsFixed(1)} km/h'
                : '0.0 km/h',
            icon: Icons.speed_rounded,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnalyticTile(
            label: 'Points',
            value: '${routePoints.length}',
            icon: Icons.location_on_rounded,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnalyticTile(
            label: 'Stops',
            value: '${stops}',
            icon: Icons.place_rounded,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _AnalyticTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
    );
  }
}
