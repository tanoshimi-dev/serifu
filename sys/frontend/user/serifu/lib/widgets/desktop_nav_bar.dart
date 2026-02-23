import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class DesktopNavBar extends StatelessWidget {
  const DesktopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/serifu-icon.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Serifu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Nav items
            _NavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: location == '/',
              onTap: () => context.go('/'),
            ),
            _NavItem(
              icon: Icons.local_fire_department,
              label: 'Feed',
              isActive: location == '/feed',
              onTap: () => context.go('/feed'),
            ),
            _NavItem(
              icon: Icons.edit,
              label: 'Write',
              isActive: location == '/write',
              onTap: () => context.go('/write'),
            ),
            _NavItem(
              icon: Icons.notifications_outlined,
              label: 'Notify',
              isActive: location == '/notifications',
              onTap: () => context.go('/notifications'),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: location == '/profile',
              onTap: () => context.go('/profile'),
            ),
            const Spacer(),
            // Search icon placeholder
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white60,
          size: 20,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: isActive ? Colors.white.withValues(alpha: 0.15) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
