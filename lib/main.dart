import 'package:flutter/material.dart';
import 'screens/check_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/community_screen.dart';
import 'screens/landing_page.dart';

void main() {
  runApp(MILHubApp());
}

class MILHubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "MIL Hub",
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0f0f0f),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: LandingPage(), // <-- Change this line
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_Feature> features = [
    _Feature(
      "Instant Check",
      "Verify links & news fast",
      Icons.search,
      Colors.indigo,
      CheckScreen(),
    ),
    _Feature(
      "Learn",
      "Mini lessons & quizzes",
      Icons.school,
      Colors.purple,
      LearnScreen(),
    ),
    _Feature(
      "Community",
      "Workshops & challenges",
      Icons.people,
      Colors.blue,
      CommunityScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        title: Text("MIL Hub", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: features[_selectedIndex].screen),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: features[_selectedIndex].color,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: features
            .map(
              (feature) => BottomNavigationBarItem(
                icon: Icon(feature.icon),
                label: feature.title,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  _Feature(this.title, this.subtitle, this.icon, this.color, this.screen);
}

//
// Instant Check Placeholder
//
class CheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.all(24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          title: const Text("🔍 Instant Check"),
        ),
        body: const Center(
          child: Text(
            "Here you’ll paste a link or news story to verify.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

//
// Learn Placeholder
//
class LearnScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.all(24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text("📚 Learn"),
        ),
        body: const Center(
          child: Text(
            "Gamified lessons, quizzes, and badges will go here.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

//
// Community Placeholder
//
class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.all(24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("👥 Community"),
        ),
        body: const Center(
          child: Text(
            "Community hub: discussions, reporting, and local language tools.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


