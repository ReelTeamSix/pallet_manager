import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:log_utils/log_utils.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> ensureUserProfileExists(String userId, String userEmail) async {
    try {
      LogUtils.info('AUTH: Checking if profile exists for user $userId');
      
      // Check if profile exists
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (profile == null) {
        LogUtils.info('AUTH: Profile not found, creating new profile');
        await _supabase.from('profiles').insert({
          'id': userId,
          'email': userEmail,
          'name': 'Default Name',
          'created_at': DateTime.now().toIso8601String(),
        });
        LogUtils.info('AUTH: Profile created successfully');
      } else {
        LogUtils.info('AUTH: Profile already exists');
      }
    } catch (e) {
      LogUtils.error('AUTH: Error ensuring profile exists: $e');
      if (e is PostgrestException) {
        LogUtils.error('AUTH: Postgrest error details - code: ${e.code}, message: ${e.message}, details: ${e.details}, hint: ${e.hint}');
      }
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      LogUtils.info('AUTH: Attempting sign in for $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        LogUtils.info('AUTH: Sign in successful for user ${response.user!.id}');
        await ensureUserProfileExists(response.user!.id, response.user!.email!);
      }
    } catch (e) {
      LogUtils.error('AUTH: Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      LogUtils.info('AUTH: Attempting sign up for $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        LogUtils.info('AUTH: Sign up successful for user ${response.user!.id}');
        await ensureUserProfileExists(response.user!.id, response.user!.email!);
      }
    } catch (e) {
      LogUtils.error('AUTH: Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      LogUtils.info('AUTH: Signing out user ${currentUser?.id}');
      await _supabase.auth.signOut();
      LogUtils.info('AUTH: Sign out successful');
    } catch (e) {
      LogUtils.error('AUTH: Sign out error: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
} 