import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/auth/presentation/screens/new_login_screen.dart';
import 'features/auth/presentation/screens/new_signup_screen.dart';
import 'features/users/dashboard/dashboard_screen.dart';
import 'screens/landing_page.dart';
import 'screens/home.dart';
import 'screens/enhanced_share_check_screen.dart' as enhanced_share;
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/share_intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependency injection
  await initializeDependencies();
  await initializeFeatureDependencies();

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
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      routes: {
        AppConstants.landingRoute: (_) => const LandingPage(),
        AppConstants.loginRoute: (_) => const NewLoginScreen(),
        AppConstants.signupRoute: (_) => const NewSignupScreen(),
        AppConstants.homeRoute: (_) => const HomeScreen(),
        AppConstants.dashboardRoute: (_) => const DashboardScreen(),
        AppConstants.linkCheckRoute: (_) => const HomeScreen(),
        AppConstants.shareCheckRoute: (_) =>
            const enhanced_share.ShareCheckScreen(),
      },
      home: const AuthWrapper(),
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
