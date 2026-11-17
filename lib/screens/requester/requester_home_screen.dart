
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_service.dart';

class RequesterHomeScreen extends StatelessWidget {
  const RequesterHomeScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible próximamente.'),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();

      if (!context.mounted) return;
      context.go('/login');
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cerrar sesión. Inténtalo nuevamente.',
          ),
        ),
      );
    }
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(
          icon,
          size: 30,
          color: colors.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
  if (title == 'Nueva solicitud') {
    context.push('/requester/new');
  } else {
    _showComingSoon(context, title);
  }
},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CyD ITMérida'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Portal de solicitudes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido al Departamento de '
                  'Comunicación y Difusión.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                Card(
                  color: colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 32,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Solicitudes institucionales',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solicita servicios de diseño, '
                          'video, cobertura y protocolo.',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  '¿Qué deseas hacer?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _actionCard(
                  context,
                  icon: Icons.note_add_outlined,
                  title: 'Nueva solicitud',
                  description:
                      'Registra uno o varios servicios.',
                ),

                const SizedBox(height: 8),

                _actionCard(
                  context,
                  icon: Icons.assignment_outlined,
                  title: 'Mis solicitudes',
                  description:
                      'Consulta el estado de tus solicitudes.',
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Los servicios de diseño y constancias '
                            'requieren al menos 5 días de anticipación.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
