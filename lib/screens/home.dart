import 'package:flutter/material.dart';
import 'package:mil_hub/constants/global_variables.dart';
import 'package:mil_hub/features/users/dashboard/dashboard_screen.dart';
import '../features/check/screens/check_screen.dart';
import '../features/learn/screens/learn_screen.dart';
import '../features/community/screens/community_screen.dart';
import 'landing_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Screens list
  final List<Widget> _screens = const [
    DashboardScreen(),
    CheckScreen(),
    LearnScreen(),
    CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: GlobalVariables.selectedNavBarColor,
        unselectedItemColor: GlobalVariables.unselectedNavBarColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Check",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Learn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Community",
          ),
        ],
      ),
    );
  }
}
