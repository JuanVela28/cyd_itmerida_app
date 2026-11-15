import 'package:cyd_itmerida_app/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'screens/auth/login_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/secretary',
      builder: (context, state) =>
          const _RolePlaceholderScreen(title: 'Agenda Secretaría'),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) =>
          const _RolePlaceholderScreen(title: 'Operación Staff CyD'),
    ),
    GoRoute(
      path: '/requester',
      builder: (context, state) => const _RolePlaceholderScreen(
        title: 'Mis Solicitudes · Jefe de Depto.',
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CyD ITMérida',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

class _RolePlaceholderScreen extends StatelessWidget {
  final String title;
  const _RolePlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Sesión iniciada en:\n$title',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
