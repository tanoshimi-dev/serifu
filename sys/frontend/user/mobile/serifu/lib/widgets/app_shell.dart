import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'bottom_nav_bar.dart';
import 'content_constraint.dart';
import 'desktop_nav_bar.dart';
import 'desktop_sidebar.dart';
import 'keyboard_shortcuts.dart';
import 'responsive_layout.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final showBottomNav = _isTabScreen(location);
    final currentIndex = _locationToIndex(location);

    return KeyboardShortcuts(
      child: ResponsiveLayout(
      mobile: Scaffold(
        body: child,
        bottomNavigationBar: showBottomNav
            ? BottomNavBar(
                currentIndex: currentIndex,
                onTap: (index) => _onNavTap(context, index),
              )
            : null,
      ),
      desktop: Scaffold(
        body: Column(
          children: [
            const DesktopNavBar(),
            Expanded(
              child: Container(
                color: AppTheme.background,
                child: Row(
                  children: [
                    Expanded(
                      child: ContentConstraint(
                        child: child,
                      ),
                    ),
                    if (showBottomNav) const DesktopSidebar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  bool _isTabScreen(String location) {
    return location == '/' ||
        location == '/feed' ||
        location == '/write' ||
        location == '/notifications' ||
        location == '/profile';
  }

  int _locationToIndex(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/feed':
        return 1;
      case '/write':
        return 2;
      case '/notifications':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/feed');
      case 2:
        context.go('/write');
      case 3:
        context.go('/notifications');
      case 4:
        context.go('/profile');
    }
  }
}
