import 'package:flutter/material.dart';

import '../presentation/activity_detail_screen/activity_detail_screen.dart';
import '../presentation/activity_history_screen/activity_history_screen.dart';
import '../presentation/auth_screen/login_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/live_tracking_screen/live_tracking_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../services/tracking_service.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String homeDashboard = '/home-dashboard-screen';
  static const String liveTracking = '/live-tracking-screen';
  static const String activityHistory = '/activity-history-screen';
  static const String activityDetail = '/activity-detail-screen';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    login: (context) => const LoginScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    liveTracking: (context) => const LiveTrackingScreen(),
    activityHistory: (context) => const ActivityHistoryScreen(),
    settings: (context) => const SettingsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case activityDetail:
        final args = settings.arguments;
        TrackingSession? session;
        if (args is TrackingSession) {
          session = args;
        } else if (args is Map<String, dynamic>) {
          final id = args['id'] as String?;
          if (id != null) {
            session = TrackingService().completedSessions
                .where((s) => s.id == id)
                .firstOrNull;
          }
        }
        return _buildPageRoute(ActivityDetailScreen(sessionData: session));
      default:
        return _buildPageRoute(const HomeDashboardScreen());
    }
  }

  static PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
