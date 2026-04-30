import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/tracking_service.dart';
import '../../../theme/app_theme.dart';

class TrackingControlsWidget extends StatefulWidget {
  final TrackingState trackingState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const TrackingControlsWidget({
    super.key,
    required this.trackingState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  State<TrackingControlsWidget> createState() => _TrackingControlsWidgetState();
}

class _TrackingControlsWidgetState extends State<TrackingControlsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _pressScale = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildControls(),
      ),
    );
  }

  List<Widget> _buildControls() {
    switch (widget.trackingState) {
      case TrackingState.idle:
      case TrackingState.stopped:
        return [
          _buildPrimaryButton(
            label: 'Start Field Session',
            icon: Icons.play_arrow_rounded,
            color: AppTheme.success,
            onTap: widget.onStart,
            wide: true,
          ),
        ];
      case TrackingState.active:
        return [
          _buildSecondaryButton(
            icon: Icons.pause_rounded,
            color: AppTheme.warning,
            onTap: widget.onPause,
          ),
          const SizedBox(width: 16),
          _buildPrimaryButton(
            label: 'Tracking...',
            icon: Icons.radio_button_checked_rounded,
            color: AppTheme.success,
            onTap: () {},
            isActive: true,
          ),
          const SizedBox(width: 16),
          _buildSecondaryButton(
            icon: Icons.stop_rounded,
            color: AppTheme.error,
            onTap: widget.onStop,
          ),
        ];
      case TrackingState.paused:
        return [
          _buildSecondaryButton(
            icon: Icons.stop_rounded,
            color: AppTheme.error,
            onTap: widget.onStop,
          ),
          const SizedBox(width: 16),
          _buildPrimaryButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            color: AppTheme.primary,
            onTap: widget.onResume,
          ),
        ];
    }
    return [];
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool wide = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTapDown: (_) => _pressController.reverse(),
      onTapUp: (_) {
        _pressController.forward();
        onTap();
      },
      onTapCancel: () => _pressController.forward(),
      child: ScaleTransition(
        scale: _pressScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withAlpha(191)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(102),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                _PulsingIcon(icon: icon, color: Colors.white)
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(102), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _s = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _s,
      child: Icon(widget.icon, color: widget.color, size: 22),
    );
  }
}
