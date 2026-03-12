import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    const _NavItem(
      path: '/explore',
      icon: Iconsax.home_2,
      activeIcon: Iconsax.home_25,
      label: 'Explore',
    ),
    const _NavItem(
      path: '/create',
      icon: Iconsax.add_circle,
      activeIcon: Iconsax.add_circle5,
      label: 'Create',
      isCenter: true,
    ),
    const _NavItem(
      path: '/decider',
      icon: Iconsax.chart,
      activeIcon: Iconsax.chart5,
      label: 'Decider',
    ),
    const _NavItem(
      path: '/profile',
      icon: Iconsax.user,
      activeIcon: Iconsax.user5,
      label: 'Profile',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndex();
  }

  void _updateIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);
        }
        return;
      }
    }
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navSurface = scheme.surface.withValues(alpha: 0.92);
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12,
    );

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: navSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isActive = _currentIndex == index;

                      if (item.isCenter) {
                        return _buildCenterButton(index, item, isActive);
                      }

                      return _buildNavItem(index, item, isActive);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, bool isActive) {
    final scheme = Theme.of(context).colorScheme;
    final inactiveColor = scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? scheme.primary : inactiveColor,
                  size: 24,
                ).animate(target: isActive ? 1 : 0).scale(
                    begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                if (isActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 150.ms)
                      .slideY(begin: 0.5, end: 0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(int index, _NavItem item, bool isActive) {
    return GestureDetector(
      onTap: () => _onTap(index),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? item.activeIcon : item.icon,
          color: Colors.white,
          size: 28,
        ),
      )
          .animate(target: isActive ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}
