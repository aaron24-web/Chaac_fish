import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  static final SupabaseClient _client = Supabase.instance.client;
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;

  static Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  static Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client
          .from('users')
          .select('id, username, story_level_unlocked')
          .eq('username', username)
          .single();
      _currentUser = response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw 'User not found';
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    _currentUser = null;
  }

  static Future<void> signUp({
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
