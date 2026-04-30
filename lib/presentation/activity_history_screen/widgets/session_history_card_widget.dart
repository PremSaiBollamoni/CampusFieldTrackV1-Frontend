import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../widgets/custom_image_widget.dart';

class SessionHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const SessionHistoryCardWidget({
    super.key,
    required this.session,
    required this.onTap,
  });

  SessionStatus _parseStatus(String s) {
    switch (s) {
      case 'active':
        return SessionStatus.active;
      case 'paused':
        return SessionStatus.paused;
      case 'completed':
        return SessionStatus.completed;
      default:
        return SessionStatus.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _parseStatus(session['status'] as String);
    final distance = session['distance'] as double;
    final coveragePercent = session['coveragePercent'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Map thumbnail header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  CustomImageWidget(
                    imageUrl: session['imageUrl'] as String,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    semanticLabel: session['semanticLabel'] as String,
                  ),
                  // Dark overlay
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x880A0F1E), Color(0x220A0F1E)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // Coverage badge top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0A0F1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 10,
                            color: coveragePercent >= 80
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$coveragePercent% covered',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Distance overlay bottom-left
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(128),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session['area'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadgeWidget(status: status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_city_rounded,
                        size: 11,
                        color: AppTheme.onDarkSubtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session['district'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.onDarkMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        session['date'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.onDarkSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.timer_rounded,
                        label: session['duration'] as String,
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.place_rounded,
                        label: '${session['stops']} stops',
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.speed_rounded,
                        label:
                            '${(session['avgSpeed'] as double).toStringAsFixed(1)} km/h',
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppTheme.onDarkSubtle),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onDarkMuted,
          ),
        ),
      ],
    );
  }
}
