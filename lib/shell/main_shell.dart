import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Tableau de bord', path: '/dashboard'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Interprètes', path: '/interpretes'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Missions', path: '/missions'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Facturation', path: '/facturation'),
    _NavItem(icon: Icons.business_outlined, activeIcon: Icons.business, label: 'Tiers', path: '/clients'),
    _NavItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, label: 'Admin', path: '/admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    return isWide ? _WideLayout(child: child) : _NarrowLayout(child: child);
  }
}

class _WideLayout extends StatelessWidget {
  final Widget child;
  const _WideLayout({required this.child});

  int _indexFromPath(String path) {
    for (var i = 0; i < MainShell._navItems.length; i++) {
      if (path.startsWith(MainShell._navItems[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexFromPath(location);
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'AMI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'AMI - Assistance missions interprètes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Bienvenue ${user?.displayName ?? ''}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 20),
                          color: AppTheme.textMuted,
                          onPressed: () async {
                            await context.read<AuthService>().logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        ...List.generate(MainShell._navItems.length, (i) {
                          final item = MainShell._navItems[i];
                          final active = i == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => context.go(item.path),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primarySoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: active ? AppTheme.primarySoft : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      active ? item.activeIcon : item.icon,
                                      size: 18,
                                      color: active ? AppTheme.primary : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                        color: active ? AppTheme.primary : AppTheme.textMuted,
                                      ),
                                    ),
                                    if (active) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.palette_outlined, size: 18),
                          label: const Text('Thèmes'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget child;
  const _NarrowLayout({required this.child});

  int _indexFromPath(String path) {
    for (var i = 0; i < MainShell._navItems.length; i++) {
      if (path.startsWith(MainShell._navItems[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexFromPath(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(MainShell._navItems[i].path),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
        destinations: MainShell._navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon, color: AppTheme.primary),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
