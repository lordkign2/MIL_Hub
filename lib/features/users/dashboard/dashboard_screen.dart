import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/enhanced_user_dashboard.dart';
import '../screens/simple_user_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If not logged in → redirect to login
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Use the simple dashboard to avoid blank screen issues
    return const SimpleUserDashboard(themeColor: Colors.purple);
  }
}
