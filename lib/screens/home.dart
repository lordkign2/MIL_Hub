import 'package:flutter/material.dart';
import 'package:mil_hub/constants/global_variables.dart';
import 'package:mil_hub/features/users/dashboard/dashboard_screen.dart';
import '../features/check/screens/check_screen.dart';
import '../features/learn/screens/learn_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../services/clipboard_monitor_service.dart';
import '../widgets/clipboard_alert_dialog.dart';
import 'landing_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isAppInForeground = true;

  // Screens list
  final List<Widget> _screens = const [
    DashboardScreen(),
    CheckScreen(),
    LearnScreen(),
    CommunityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check clipboard when app comes to foreground
    if (state == AppLifecycleState.resumed && !_isAppInForeground) {
      _isAppInForeground = true;
      _checkClipboardOnResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
    }
  }

  /// Checks clipboard when app resumes and shows dialog if suspicious content found
  Future<void> _checkClipboardOnResume() async {
    try {
      final checkResult =
          await ClipboardMonitorService.checkClipboardOnResume();

      if (checkResult != null && checkResult.shouldShowDialog && mounted) {
        // Add a small delay to ensure the app is fully resumed
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          _showClipboardAlert(checkResult);
        }
      }
    } catch (e) {
      // Silently handle any errors - clipboard monitoring should not break the app
      debugPrint('Clipboard check error: $e');
    }
  }

  /// Shows the clipboard alert dialog
  void _showClipboardAlert(ClipboardCheckResult checkResult) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ClipboardAlertDialog(checkResult: checkResult),
    );
  }

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Check"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Learn"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
        ],
      ),
    );
  }
}
