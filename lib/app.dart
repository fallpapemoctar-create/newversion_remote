import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/interpretes/interpretes_screen.dart';
import 'features/missions/missions_screen.dart';
import 'features/clients/clients_screen.dart';
import 'features/facturation/facturation_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/theme/theme_screen.dart';
import 'shell/main_shell.dart';
import 'core/theme/app_theme.dart';

class AmiApp extends StatefulWidget {
  const AmiApp({super.key});

  @override
  State<AmiApp> createState() => _AmiAppState();
}

class _AmiAppState extends State<AmiApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _router = GoRouter(
      initialLocation: '/dashboard',
      redirect: (ctx, state) {
        final loggedIn = auth.isLoggedIn;
        final goingToLogin = state.matchedLocation == '/login';
        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/dashboard';
        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (_, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
            GoRoute(path: '/interpretes', builder: (_, _) => const InterpretesScreen()),
            GoRoute(path: '/missions', builder: (_, _) => const MissionsScreen()),
            GoRoute(path: '/clients', builder: (_, _) => const ClientsScreen()),
            GoRoute(path: '/facturation', builder: (_, _) => const FacturationScreen()),
            GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
            GoRoute(path: '/themes', builder: (_, _) => const ThemeScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AMI',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

