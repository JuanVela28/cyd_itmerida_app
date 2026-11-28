
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';

/// Represents an institutional user registered in CyD.
class ManagedUser {
  final String id;
  final String fullName;
  final String department;
  final String role;

  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.department,
    required this.role,
  });

  /// Converts a Supabase profile record into a ManagedUser.
  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final name = json['full_name']?.toString().trim() ?? '';
    final department =
        json['department']?.toString().trim() ?? '';

    return ManagedUser(
      id: json['id'].toString(),
      fullName: name.isEmpty ? 'Usuario sin nombre' : name,
      department: department.isEmpty
          ? 'Departamento no registrado'
          : department,
      role: json['role']?.toString() ?? 'unknown',
    );
  }
}

/// Provides administrative read access to user profiles.
class UserManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Fetches all profiles visible to an authenticated administrator.
  Future<List<ManagedUser>> fetchUsers() async {
    final user = _supabase.auth.currentUser;
   
    if (user == null) {
      throw StateError('Debes iniciar sesión.');
    }

    final role = await _authService.getCurrentUserRole();

    if (role != 'admin') {
      throw StateError(
        'No tienes permisos para consultar usuarios.',
      );
    }

    final rows = await _supabase
        .from('profiles')
        .select('id, full_name, department, role')
        .order('full_name', ascending: true);

    return rows
        .map((row) => ManagedUser.fromJson(row))
        .toList();
  }


  /// Invites a new institutional user through the secure backend.
  Future<void> createUser({
    required String fullName,
    required String email,
    required String department,
    required String role,
  }) async {
    if (_supabase.auth.currentUser == null) {
      throw StateError('Debes iniciar sesión.');
    }

    try {
      final response = await _supabase.functions.invoke(
        'admin-create-user',
        body: {
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'department': department.trim(),
          'role': role,
        },
      );

      final result = response.data;

      if (result is! Map || result['success'] != true) {
        throw StateError(
          result is Map
              ? (result['error']?.toString() ??
                  'No se pudo registrar el usuario.')
              : 'Respuesta inesperada del servidor.',
        );
      }
    } on FunctionException catch (error) {
  throw StateError(
    'No se pudo registrar el usuario: '
    '${error.reasonPhrase ?? error.toString()}',
  );
}
  }

}
