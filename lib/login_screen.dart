import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  // ... (existing code)
}

class _LoginScreenState extends State<LoginScreen> {
  // ... (existing code)

  void _handleLoginSuccess(String email) async {
    setState(() {
      _isLoading = false;
    });

    print('Login successful for $email');
    
    // Use the comprehensive navigation approach to ensure clear routing
    await Future.delayed(Duration(milliseconds: 300)); // Brief delay to allow auth state to propagate
    
    print('Navigating from login screen after successful login');
    // Use the more forceful navigation to ensure we properly reset the app state
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Attempting sign in with email: ${_emailController.text}');
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          _handleLoginSuccess(_emailController.text.trim());
        } else {
          _showErrorSnackBar('Login failed');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error during login: $e');
        _showErrorSnackBar('Error: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ... (rest of the existing code)
} 