import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_service.dart';
import '../../shared/widgets/institutional_logos.dart';

class RequesterHomeScreen extends StatefulWidget {
  const RequesterHomeScreen({super.key});

  @override
  State<RequesterHomeScreen> createState() => _RequesterHomeScreenState();
}

class _RequesterHomeScreenState extends State<RequesterHomeScreen> {
  final AuthService _authService = AuthService();

  String _fullName = 'Usuario';
  String _department = 'Departamento no registrado';
  bool _isLoadingProfile = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _fullName = 'Sin sesión activa';
          _department = 'No disponible';
          _isLoadingProfile = false;
        });
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, department')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final name = profile?['full_name']?.toString().trim() ?? '';
      final department = profile?['department']?.toString().trim() ?? '';

      setState(() {
        _fullName = name.isEmpty ? 'Usuario' : name;
        _department = department.isEmpty
            ? 'Departamento no registrado'
            : department;
        _isLoadingProfile = false;
      });
    } catch (error) {
      debugPrint('Error loading requester profile: $error');
      if (!mounted) return;
      setState(() {
        _fullName = 'Usuario';
        _department = 'Departamento no disponible';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Inténtalo nuevamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  String get _initials {
    final parts = _fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 18,
        22,
        52,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGuinda, AppColors.primaryGuindaDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
                onPressed: _isSigningOut ? null : _signOut,
                tooltip: 'Cerrar sesión',
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'DEPARTAMENTO DE COMUNICACIÓN Y DIFUSIÓN',
            style: TextStyle(
              color: AppColors.secondaryGold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Portal de solicitudes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Servicios institucionales de diseño, video, '
            'cobertura y protocolo.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: AppColors.primaryGuindaLight,
              child: _isLoadingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGuinda,
                      ),
                    )
                  : Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.primaryGuinda,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIENVENIDO A CyD',
                    style: TextStyle(
                      color: AppColors.secondaryGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isLoadingProfile ? 'Cargando perfil...' : _fullName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _isLoadingProfile
                              ? 'Consultando departamento...'
                              : _department,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary
                        ? AppColors.primaryGuinda
                        : AppColors.primaryGuindaLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 27,
                    color: primary ? Colors.white : AppColors.primaryGuinda,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 17,
                  color: AppColors.secondaryGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utiliza la tipografía definida en el tema institucional.
    final screenTheme = Theme.of(context);

    return Theme(
      data: screenTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.primaryGuinda,
        ),
        child: Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: RefreshIndicator(
            onRefresh: _loadProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _buildHero(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildProfileCard(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Qué deseas hacer?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selecciona una opción para continuar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildActionCard(
                        icon: Icons.note_add_rounded,
                        title: 'Nueva solicitud',
                        description: 'Registra uno o varios servicios.',
                        primary: true,
                        onTap: () => context.push('/requester/new'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.assignment_outlined,
                        title: 'Mis solicitudes',
                        description: 'Consulta el estado de tus trámites.',
                        onTap: () => context.push('/requester/requests'),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGuindaLight,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: AppColors.primaryGuinda.withValues(
                              alpha: 0.10,
                            ),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primaryGuinda,
                              size: 22,
                            ),
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Los servicios de diseño y constancias '
                                'requieren al menos 5 días de anticipación.',
                                style: TextStyle(
                                  color: AppColors.primaryGuindaDark,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Instituto Tecnológico de Mérida',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
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
