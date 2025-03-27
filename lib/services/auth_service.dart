import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> ensureUserProfileExists(String userId, String userEmail) async {
    try {
      debugPrint('AUTH: Checking if profile exists for user $userId');
      
      // Check if profile exists
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (profile == null) {
        debugPrint('AUTH: Profile not found, creating new profile');
        await _supabase.from('profiles').insert({
          'id': userId,
          'email': userEmail,
          'name': 'Default Name',
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('AUTH: Profile created successfully');
      } else {
        debugPrint('AUTH: Profile already exists');
      }
    } catch (e) {
      debugPrint('AUTH: Error ensuring profile exists: $e');
      if (e is PostgrestException) {
        debugPrint('AUTH: Postgrest error details - code: ${e.code}, message: ${e.message}, details: ${e.details}, hint: ${e.hint}');
      }
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      debugPrint('AUTH: Attempting sign in for $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('AUTH: Sign in successful for user ${response.user!.id}');
        await ensureUserProfileExists(response.user!.id, response.user!.email!);
      }
    } catch (e) {
      debugPrint('AUTH: Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      debugPrint('AUTH: Attempting sign up for $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('AUTH: Sign up successful for user ${response.user!.id}');
        await ensureUserProfileExists(response.user!.id, response.user!.email!);
      }
    } catch (e) {
      debugPrint('AUTH: Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('AUTH: Signing out user ${currentUser?.id}');
      await _supabase.auth.signOut();
      debugPrint('AUTH: Sign out successful');
    } catch (e) {
      debugPrint('AUTH: Sign out error: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
} 