import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/history_filter_bar_widget.dart';
import './widgets/weekly_summary_strip_widget.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  int _selectedFilter = 0;
  late AnimationController _listController;

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _trackingService.addListener(_onUpdate);
    _trackingService.initialize();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _trackingService.removeListener(_onUpdate);
    _listController.dispose();
    super.dispose();
  }

  List<TrackingSession> get _filteredSessions {
    final now = DateTime.now();
    final sessions = _trackingService.completedSessions;
    switch (_selectedFilter) {
      case 1: // Today
        return sessions
            .where(
              (s) =>
                  s.startTime.year == now.year &&
                  s.startTime.month == now.month &&
                  s.startTime.day == now.day,
            )
            .toList();
      case 2: // This Week
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return sessions
            .where(
              (s) => s.startTime.isAfter(
                DateTime(weekStart.year, weekStart.month, weekStart.day),
              ),
            )
            .toList();
      case 3: // This Month
        return sessions
            .where(
              (s) =>
                  s.startTime.year == now.year &&
                  s.startTime.month == now.month,
            )
            .toList();
      default:
        return sessions.toList();
    }
  }

  Future<void> _onRefresh() async {
    await _trackingService.initialize();
    _listController.forward(from: 0);
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSessions;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceVariant,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: WeeklySummaryStripWidget(
                          sessions: _trackingService.completedSessions.toList(),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: HistoryFilterBarWidget(
                          filters: _filters,
                          selectedIndex: _selectedFilter,
                          onFilterSelected: (i) {
                            setState(() => _selectedFilter = i);
                            _listController.forward(from: 0);
                          },
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: EmptyStateWidget(
                            icon: Icons.route_rounded,
                            title: 'No sessions found',
                            description:
                                'Start a field session to see your history here',
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final session = filtered[i];
                          final delay = (i * 0.08).clamp(0.0, 0.6);
                          final anim = CurvedAnimation(
                            parent: _listController,
                            curve: Interval(
                              delay,
                              (delay + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  10,
                                ),
                                child: _SessionHistoryCard(
                                  session: session,
                                  formatDuration: _formatDuration,
                                  formatDate: _formatDate,
                                  onDelete: () async {
                                    await _trackingService.deleteSession(
                                      session.id,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, AppRoutes.homeDashboard);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.liveTracking);
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.homeDashboard),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.onDark,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity History',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onDark,
                  ),
                ),
                Text(
                  '${_trackingService.completedSessions.length} sessions recorded',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final TrackingSession session;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;
  final VoidCallback onDelete;

  const _SessionHistoryCard({
    required this.session,
    required this.formatDuration,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final coveragePercent = ((session.distanceKm / 20.0) * 100)
        .clamp(0.0, 100.0)
        .round();

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.activityDetail,
          arguments: session,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.areaName ??
                              'Session ${formatDate(session.startTime)}',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${formatDate(session.startTime)} · ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppTheme.onDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Completed',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatPill(
                    icon: Icons.route_rounded,
                    label: '${session.distanceKm.toStringAsFixed(2)} km',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    icon: Icons.timer_rounded,
                    label: formatDuration(session.durationSeconds),
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    icon: Icons.place_rounded,
                    label: '${session.checkpoints.length} stops',
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: coveragePercent / 100,
                        backgroundColor: AppTheme.glassBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$coveragePercent%',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onDark,
            ),
          ),
        ],
      ),
    );
  }
}
