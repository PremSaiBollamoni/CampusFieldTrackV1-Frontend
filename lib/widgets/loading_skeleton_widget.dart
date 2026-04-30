import 'package:flutter/material.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmer.value - 0.5).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardSkeletonWidget extends StatelessWidget {
  const DashboardSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const LoadingSkeletonWidget(
                width: 120,
                height: 16,
                borderRadius: 8,
              ),
              const Spacer(),
              const LoadingSkeletonWidget(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: const LoadingSkeletonWidget(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const LoadingSkeletonWidget(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeletonWidget(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
          const SizedBox(height: 24),
          const LoadingSkeletonWidget(width: 100, height: 16, borderRadius: 8),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingSkeletonWidget(
                width: double.infinity,
                height: 80,
                borderRadius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
