import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/export_service.dart';
import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class ExportActionsWidget extends StatelessWidget {
  final TrackingSession session;

  const ExportActionsWidget({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Session',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        const SizedBox(height: 12),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.map_rounded,
                          label: 'GPX File',
                          sublabel: 'GPS route data',
                          color: AppTheme.primary,
                          onTap: () => ExportService().exportAndShare(
                            context,
                            session,
                            'GPX',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.table_chart_rounded,
                          label: 'CSV File',
                          sublabel: 'Spreadsheet data',
                          color: AppTheme.success,
                          onTap: () => ExportService().exportAndShare(
                            context,
                            session,
                            'CSV',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.data_object_rounded,
                          label: 'JSON Data',
                          sublabel: 'Raw route data',
                          color: AppTheme.secondary,
                          onTap: () => ExportService().exportAndShare(
                            context,
                            session,
                            'JSON',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy GPX',
                          sublabel: 'To clipboard',
                          color: AppTheme.warning,
                          onTap: () {
                            final gpx = ExportService().generateGpx(session);
                            ExportService().exportAndShare(
                              context,
                              session,
                              'GPX',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _c;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) {
        _c.forward();
        widget.onTap();
      },
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withAlpha(64)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onDark,
                      ),
                    ),
                    Text(
                      widget.sublabel,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppTheme.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
