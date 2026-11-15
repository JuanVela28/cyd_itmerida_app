import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<String> signInAndGetRole({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('No se pudo iniciar sesión.');
    }

    return await getCurrentUserRole();
  }

  Future<String> getCurrentUserRole() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 'unauthenticated';

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return data['role'] as String;
  }

  Future<String> getCurrentUserName() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 'Administración';

    final data = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    final fullName = data?['full_name'] as String?;
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Administración';
    }
    return fullName.trim();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
