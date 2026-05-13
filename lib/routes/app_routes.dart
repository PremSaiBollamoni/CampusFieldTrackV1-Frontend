import 'package:flutter/material.dart';

import '../presentation/about_screen/about_screen.dart';
import '../presentation/activity_detail_screen/activity_detail_screen.dart';
import '../presentation/activity_history_screen/activity_history_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/auth_screen/login_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/live_tracking_screen/live_tracking_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
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
  static const String profile = '/profile-screen';
  static const String about = '/about-screen';
  static const String adminDashboard = '/admin-dashboard';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    liveTracking: (context) => const LiveTrackingScreen(),
    activityHistory: (context) => const ActivityHistoryScreen(),
    settings: (context) => const SettingsScreen(),
    profile: (context) => const ProfileScreen(),
    about: (context) => const AboutScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
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
      case profile:
        return _buildPageRoute(const ProfileScreen());
      case about:
        return _buildPageRoute(const AboutScreen());
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
