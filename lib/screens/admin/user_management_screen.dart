import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/users/user_management_service.dart';
import '../../shared/widgets/institutional_logos.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementService _service = UserManagementService();

  static const _roleFilters = [
    ('all', 'Todos'),
    ('admin', 'Administración'),
    ('requester', 'Solicitantes'),
    ('secretary', 'Secretaría'),
    ('staff', 'Personal'),
  ];

  List<ManagedUser> _users = [];

  String _searchQuery = '';
  String _selectedRole = 'all';
  String? _errorMessage;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Loads the institutional user directory.
  Future<void> _loadUsers({bool showLoader = true}) async {
    if (!mounted) return;

    setState(() {
      if (showLoader) _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _service.fetchUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('User management error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar el directorio de usuarios. '
            'Verifica tus permisos y la conexión con Supabase.';
      });
    }
  }

  /// Applies the name, department, and role filters.
  List<ManagedUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    return _users.where((user) {
      final matchesRole = _selectedRole == 'all' || user.role == _selectedRole;

      final matchesSearch =
          query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.department.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);

      return matchesRole && matchesSearch;
    }).toList();
  }

  /// Converts database roles into readable Spanish labels.
  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'Administración',
      'requester' => 'Solicitante',
      'secretary' => 'Secretaría',
      'staff' => 'Personal',
      _ => 'Sin rol definido',
    };
  }

  /// Generates initials for the user's avatar.
  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);

    final value = words.map((word) => word[0].toUpperCase()).join();

    return value.isEmpty ? 'U' : value;
  }

  /// Builds the institutional header.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Regresar',
                onPressed: () => context.go('/admin'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primaryGuinda,
                ),
              ),
              const Expanded(
                child: Center(
                  child: InstitutionalLogos(height: 42, withBackground: true),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar usuarios',
                onPressed: _isLoading ? null : () => _loadUsers(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primaryGuinda,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'ADMINISTRACIÓN',
            style: TextStyle(
              color: AppColors.secondaryGold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Gestión de usuarios',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Consulta los usuarios institucionales registrados.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Text(
            _isLoading
                ? 'Consultando usuarios...'
                : '${_users.length} usuarios registrados',
            style: const TextStyle(
              color: AppColors.primaryGuinda,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuevo usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGuinda,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search field and role filters.
  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o departamento...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryGuinda,
              ),
              filled: true,
              fillColor: AppColors.surfaceWhite,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 43,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _roleFilters.map((filter) {
              final selected = _selectedRole == filter.$1;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter.$2),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primaryGuinda,
                  backgroundColor: AppColors.surfaceWhite,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryGuinda
                        : AppColors.borderSubtle,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedRole = filter.$1;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Builds a card containing the user's profile details.
  Widget _buildUserCard(ManagedUser user) {
    final isAdmin = user.role == 'admin';

    final badgeColor = isAdmin
        ? AppColors.primaryGuinda
        : AppColors.statusReviewText;

    final badgeBackground = isAdmin
        ? AppColors.primaryGuindaLight
        : AppColors.statusReviewBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryGuindaLight,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: AppColors.primaryGuinda,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.textMuted,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            user.department,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(user.role),
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the institutional user registration form.
  Future<void> _showCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();

    String fullName = '';
    String email = '';
    String department = '';

    String selectedRole = 'requester';
    String? errorMessage;
    bool isSaving = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar usuario'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          onChanged: (value) => fullName = value,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if ((value?.trim().length ?? 0) < 3) {
                              return 'Ingresa un nombre válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          onChanged: (value) => email = value,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(email)) {
                              return 'Ingresa un correo válido.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          onChanged: (value) => department = value,
                          decoration: const InputDecoration(
                            labelText: 'Departamento',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                          validator: (value) {
                            if ((value?.trim().length ?? 0) < 2) {
                              return 'Ingresa el departamento.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: const [
                            DropdownMenuItem(
                              value: 'requester',
                              child: Text('Solicitante'),
                            ),
                            DropdownMenuItem(
                              value: 'secretary',
                              child: Text('Secretaría'),
                            ),
                            DropdownMenuItem(
                              value: 'staff',
                              child: Text('Personal'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Administración'),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    selectedRole = value;
                                  }
                                },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });

                          try {
                            await _service.createUser(
                              fullName: fullName.trim(),
                              email: email.trim(),
                              department: department.trim(),
                              role: selectedRole,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              isSaving = false;
                              errorMessage = error.toString();
                            });
                          }
                        },
                  child: Text(
                    isSaving ? 'Registrando...' : 'Enviar invitación',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      await _loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Usuario registrado. Revisa el envío de la invitación.',
          ),
          backgroundColor: AppColors.primaryGuinda,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGuinda,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.errorRed,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadUsers(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryGuinda,
                      onRefresh: () => _loadUsers(showLoader: false),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.isEmpty ? 1 : filtered.length,
                        itemBuilder: (context, index) {
                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  'No se encontraron usuarios.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            );
                          }

                          return _buildUserCard(filtered[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
