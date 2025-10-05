import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mil_hub/features/users/dashboard/dashboard_screen.dart';
import 'package:mil_hub/screens/landing_page.dart';
import 'features/auth/services/auth_wrapper.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/enhanced_share_check_screen.dart' as enhanced_share;
import 'constants/global_variables.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'services/share_intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MILHubApp());
}

class MILHubApp extends StatelessWidget {
  const MILHubApp({super.key});

  // Create global navigator key for share intent navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Initialize share intent service
    ShareIntentService.initialize(navigatorKey);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "MIL Hub",
      theme: ThemeData.dark().copyWith(
        primaryColor: GlobalVariables.secondaryColor,
        scaffoldBackgroundColor: GlobalVariables.backgroundColor,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      routes: {
        "/landing": (_) => const LandingPage(),
        "/login": (_) => const LoginScreen(),
        "/signup": (_) => const SignupScreen(),
        "/home": (_) => const HomeScreen(),
        "/dashboard": (_) => const DashboardScreen(),
        "/link-check": (_) =>
            const HomeScreen(), // Navigate to home and show check tab
        "/share-check": (_) =>
            const enhanced_share.ShareCheckScreen(), // Enhanced share check route
      },
      home: FirebaseAuth.instance.currentUser == null
          ? LandingPage()
          : const HomeScreen(),
    );
  }
}

/* 
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_Feature> features = [
    _Feature(
      "Home",
      "Welcome screen",
      Icons.home,
      Colors.deepPurple,
      LandingPage(),
    ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: features[_selectedIndex].color,
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            items: features
                .map(
                  (feature) => BottomNavigationBarItem(
                    icon: Icon(feature.icon),
                    label: feature.title,
                  ),
                )
                .toList(),
          ),
        ),
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
} */
