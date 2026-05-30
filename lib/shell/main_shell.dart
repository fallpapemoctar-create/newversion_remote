import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(label: 'Tableau de bord', path: '/dashboard'),
    _NavItem(label: 'Interprètes', path: '/interpretes'),
    _NavItem(label: 'Missions', path: '/missions'),
    _NavItem(label: 'Facturation', path: '/facturation'),
    _NavItem(label: 'Tiers', path: '/clients'),
    _NavItem(label: 'Admin', path: '/admin'),
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
    final themesActive = location.startsWith('/themes');
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
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.go(item.path),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primarySoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: active ? AppTheme.primary : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                    color: active ? AppTheme.primary : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.go('/themes'),
                          icon: const Icon(Icons.palette_outlined, size: 18),
                          label: const Text('Thèmes'),
                          style: TextButton.styleFrom(
                            foregroundColor: themesActive ? AppTheme.primary : AppTheme.textMuted,
                            backgroundColor: themesActive ? AppTheme.primarySoft : Colors.transparent,
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
    final themesActive = location.startsWith('/themes');
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
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'AMI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'AMI - Assistance missions interprètes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.logout, size: 18),
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
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...List.generate(MainShell._navItems.length, (i) {
                            final item = MainShell._navItems[i];
                            final active = i == idx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => context.go(item.path),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active ? AppTheme.primarySoft : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: active ? AppTheme.primary : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                        color: active ? AppTheme.primary : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => context.go('/themes'),
                            icon: const Icon(Icons.palette_outlined, size: 14),
                            label: const Text('Thèmes'),
                            style: TextButton.styleFrom(
                              foregroundColor: themesActive ? AppTheme.primary : AppTheme.textMuted,
                              backgroundColor: themesActive ? AppTheme.primarySoft : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (user?.displayName != null && user!.displayName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Bienvenue ${user.displayName}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

class _NavItem {
  final String label;
  final String path;
  const _NavItem({
    required this.label,
    required this.path,
  });
}
