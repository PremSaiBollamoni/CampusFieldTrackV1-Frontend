import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SessionStatus { active, paused, completed, idle }

class StatusBadgeWidget extends StatelessWidget {
  final SessionStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SessionStatus.active) ...[
            _PulsingDot(color: config.dotColor),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: config.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            config.label,
            style: GoogleFonts.manrope(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case SessionStatus.active:
        return _BadgeConfig(
          label: 'ACTIVE',
          bgColor: const Color(0x2010B981),
          borderColor: const Color(0x5010B981),
          dotColor: const Color(0xFF10B981),
          textColor: const Color(0xFF10B981),
        );
      case SessionStatus.paused:
        return _BadgeConfig(
          label: 'PAUSED',
          bgColor: const Color(0x20F59E0B),
          borderColor: const Color(0x50F59E0B),
          dotColor: const Color(0xFFF59E0B),
          textColor: const Color(0xFFF59E0B),
        );
      case SessionStatus.completed:
        return _BadgeConfig(
          label: 'COMPLETED',
          bgColor: const Color(0x203B82F6),
          borderColor: const Color(0x503B82F6),
          dotColor: const Color(0xFF3B82F6),
          textColor: const Color(0xFF3B82F6),
        );
      case SessionStatus.idle:
        return _BadgeConfig(
          label: 'IDLE',
          bgColor: const Color(0x206B7280),
          borderColor: const Color(0x506B7280),
          dotColor: const Color(0xFF6B7280),
          textColor: const Color(0xFF9CA3AF),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color dotColor;
  final Color textColor;

  _BadgeConfig({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.dotColor,
    required this.textColor,
  });
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
