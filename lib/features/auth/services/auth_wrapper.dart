// /features/auth/services/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../screens/home.dart';
import '../screens/login_screen.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Splash/loading screen
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in → go to Home
          return const HomeScreen();
        }

        // User not logged in → go to Login
        return const LoginScreen();
      },
    );
  }
}
