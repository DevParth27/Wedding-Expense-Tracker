import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shaadi/screens/auth/login_screen.dart';
import 'package:shaadi/screens/dashboard/dashboard_screen.dart';
import 'package:shaadi/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const DashboardScreen();
        }

        // Show loading indicator while waiting for auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
