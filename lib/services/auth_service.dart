import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:pallet_manager/utils/log_utils.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabaseClient = SupabaseService.instance.client;

  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;
  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<bool> ensureUserProfileExists() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        LogUtils.warning('Cannot ensure user profile exists: User not authenticated');
        return false;
      }
      
      // Check if user profile exists
      final response = await _supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response == null) {
        LogUtils.info('Creating new user profile for ${user.email}');
        
        // Create a new user profile
        await _supabaseClient.from('user_profiles').insert({
          'user_id': user.id,
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        LogUtils.info('Successfully created user profile');
        return true;
      }
      
      LogUtils.info('User profile already exists');
      return true;
    } catch (e) {
      LogUtils.error('Error ensuring user profile exists', e);
      return false;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      LogUtils.info('Signing in user with email: $email');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        LogUtils.info('Successfully signed in: ${response.user!.email}');
        await ensureUserProfileExists();
      }
      
      return response;
    } catch (e) {
      LogUtils.error('Error signing in with email', e);
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      LogUtils.info('Creating new account for email: $email');
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        LogUtils.info('Successfully created account: ${response.user!.email}');
        await ensureUserProfileExists();
      }
      
      return response;
    } catch (e) {
      LogUtils.error('Error creating account with email', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      LogUtils.info('Signing out user');
      await _supabaseClient.auth.signOut();
      LogUtils.info('User signed out successfully');
    } catch (e) {
      LogUtils.error('Error signing out', e);
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
} 