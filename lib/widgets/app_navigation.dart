import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.radio_button_unchecked_rounded,
      activeIcon: Icons.radio_button_checked_rounded,
      label: 'Track',
    ),
    _NavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
      label: 'History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final isActive = currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0x303B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 130),
                            child: Icon(
                              isActive
                                  ? _items[index].activeIcon
                                  : _items[index].icon,
                              key: ValueKey(isActive),
                              size: 22,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[index].label,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  // TODO: Replace with Riverpod provider for navigation state

  final List<String> _routes = [
    AppRoutes.homeDashboard,
    AppRoutes.liveTracking,
    AppRoutes.activityHistory,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _routes.map((route) {
          switch (route) {
            case AppRoutes.liveTracking:
              // Lazy import inside shell
              return _RouteHolder(routeName: route);
            default:
              return _RouteHolder(routeName: route);
          }
        }).toList(),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          // TODO: Replace with Riverpod navigation state
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _RouteHolder extends StatelessWidget {
  final String routeName;
  const _RouteHolder({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Navigator.of(context, rootNavigator: false).widget.runtimeType ==
            Navigator
        ? const SizedBox.shrink()
        : const SizedBox.shrink();
  }
}