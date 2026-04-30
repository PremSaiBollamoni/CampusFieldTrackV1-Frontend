import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CheckpointTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> checkpoints;

  const CheckpointTimelineWidget({super.key, required this.checkpoints});

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Checkpoints',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.secondaryMuted,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${checkpoints.length}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: List.generate(checkpoints.length, (i) {
                  final cp = checkpoints[i];
                  final isLast = i == checkpoints.length - 1;
                  final arrivedAt = cp['arrivedAt'] as String?;
                  final duration = cp['duration'] as String? ?? '—';
                  final index = (cp['index'] as int?) ?? i;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 52,
                          child: Column(
                            children: [
                              if (i == 0)
                                const SizedBox(height: 16)
                              else
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Container(
                                      width: 1.5,
                                      color: AppTheme.glassBorder,
                                    ),
                                  ),
                                ),
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMuted,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      width: 1.5,
                                      color: AppTheme.glassBorder,
                                    ),
                                  ),
                                ),
                              if (isLast) const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: i == 0 ? 16 : 8,
                              bottom: isLast ? 16 : 8,
                              right: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stop ${index + 1}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (arrivedAt != null) ...[
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: AppTheme.onDarkSubtle,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTime(arrivedAt),
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: AppTheme.onDarkMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Icon(
                                      Icons.hourglass_bottom_rounded,
                                      size: 11,
                                      color: AppTheme.onDarkSubtle,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$duration visit',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppTheme.onDarkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoString;
    }
  }
}
