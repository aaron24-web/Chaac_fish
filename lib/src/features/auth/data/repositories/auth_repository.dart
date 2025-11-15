import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('username', username)
          .single();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw 'User not found';
      }
      rethrow;
    }
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _client.from('users').insert([
        {
          'username': username,
          'email': email,
          // Storing plain text passwords is a bad practice.
          // This is just for demonstration purposes.
          // 'password': password,
        }
      ]);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw 'User already exists';
      }
      rethrow;
    }
  }
}
