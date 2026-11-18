import 'package:cyd_itmerida_app/screens/admin/admin_dashboard_screen.dart';
import 'package:cyd_itmerida_app/screens/admin/request_management_screen.dart';
import 'package:cyd_itmerida_app/screens/secretary/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/requester/my_requests_screen.dart';
import 'screens/requester/requester_home_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/requester/new_request/new_request_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/schedule',
      builder: (context, state) => const ScheduleScreen(canCreateEvents: true),
    ),
    GoRoute(
      path: '/admin/requests',
      builder: (context, state) => const RequestManagementScreen(),
    ),
    GoRoute(
      path: '/secretary',
      builder: (context, state) => const ScheduleScreen(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const ScheduleScreen(canCreateEvents: false),
    ),
    GoRoute(
      path: '/requester',
      builder: (context, state) => const RequesterHomeScreen(),
    ),
    GoRoute(
      path: '/requester/new',
      builder: (context, state) => const NewRequestScreen(),
    ),
    GoRoute(
      path: '/requester/requests',
      builder: (context, state) => const MyRequestsScreen(),
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
