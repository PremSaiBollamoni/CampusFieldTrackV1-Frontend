import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class GlassStatChipRowWidget extends StatelessWidget {
  final double distanceKm;
  final int durationSeconds;
  final int stops;
  final double speedKmh;
  final String Function(int) formatDuration;

  const GlassStatChipRowWidget({
    super.key,
    required this.distanceKm,
    required this.durationSeconds,
    required this.stops,
    required this.speedKmh,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GlassChip(
            icon: Icons.route_rounded,
            value: distanceKm.toStringAsFixed(2),
            unit: 'km',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassChip(
            icon: Icons.timer_rounded,
            value: formatDuration(durationSeconds),
            unit: '',
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassChip(
            icon: Icons.place_rounded,
            value: '$stops',
            unit: 'stops',
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassChip(
            icon: Icons.speed_rounded,
            value: speedKmh.toStringAsFixed(1),
            unit: 'km/h',
            color: AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _GlassChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xBB111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(77), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
