import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_service.dart';
import '../../features/schedule/schedule_service.dart';
import '../../shared/widgets/institutional_logos.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _scheduleService = ScheduleService();

  String _userName = '...';
  int _todayEventsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final name = await _authService.getCurrentUserName();
    int todayCount = 0;
    try {
      todayCount = await _scheduleService.countTodayEvents();
    } catch (_) {
      todayCount = 0;
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _todayEventsCount = todayCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera institucional guinda
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGuinda,
                    AppColors.primaryGuindaDark,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Identidad institucional.
                      const Flexible(child: InstitutionalLogos(height: 52)),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Cerrar sesión',
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'PANEL DE ADMINISTRACIÓN',
                    style: TextStyle(
                      color: AppColors.secondaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hola, $_userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Tarjetas de resumen rápido
                  const Text(
                    'Resumen general',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard(
                        label: 'Pendientes',
                        value: '0',
                        bgColor: AppColors.statusPendingBg,
                        textColor: AppColors.statusPendingText,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        label: 'En revisión',
                        value: '0',
                        bgColor: AppColors.statusReviewBg,
                        textColor: AppColors.statusReviewText,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        label: 'Para hoy',
                        value: '$_todayEventsCount',
                        bgColor: AppColors.statusDoneBg,
                        textColor: AppColors.statusDoneText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 3. Módulos principales del Admin
                  const Text(
                    'Módulos del sistema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.inbox_rounded,
                    title: 'Solicitudes recibidas',
                    subtitle: 'Revisar, aprobar o rechazar trámites',
                    onTap: () => context.push('/admin/requests'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Agenda institucional',
                    subtitle: 'Ver eventos y programaciones de CyD',
                    onTap: () async {
                      await context.push('/admin/schedule');
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.people_alt_rounded,
                    title: 'Gestión de usuarios',
                    subtitle: 'Altas y bajas de jefes de departamento y equipo',
                    onTap: () {
                      // Próximo módulo a conectar
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGuindaLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryGuinda, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
