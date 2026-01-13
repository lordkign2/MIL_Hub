import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mil_hub/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Integration Tests', () {
    testWidgets('App launches and navigates to dashboard', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Verify that the app launches without errors
      expect(find.byType(MaterialApp), findsOneWidget);

      // The app should either show the dashboard or redirect to login
      // Both are valid behaviors depending on authentication state
      final dashboardFound = find.text('Loading your dashboard...');
      final loginFound = find.text('Login');

      // Either dashboard or login screen should be present
      expect(
        dashboardFound.evaluate().isEmpty && loginFound.evaluate().isEmpty,
        isFalse,
      );
    });

    testWidgets('Dashboard displays core components when loaded', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Wait for initial loading
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test for core dashboard UI elements that should always be present
      // These tests will pass if dashboard is shown, and gracefully fail if redirected to login

      // Test for basic scaffold structure
      expect(find.byType(Scaffold), findsWidgets);

      // Test for scrollable dashboard content
      expect(find.byType(CustomScrollView), findsWidgets);

      // Test for refresh indicator functionality
      expect(find.byType(RefreshIndicator), findsWidgets);

      // Test for key dashboard sections by looking for common widget types
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Dashboard handles user profile display', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Wait for UI to settle
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test for profile-related UI elements
      // These should exist in the dashboard regardless of actual user data
      expect(find.byType(ClipOval), findsWidgets); // Profile image container
      expect(
        find.byIcon(Icons.person_rounded),
        findsWidgets,
      ); // Default avatar icon

      // Test for text elements that should always be present
      expect(find.text('Welcome to MIL Hub'), findsWidgets);
    });

    testWidgets('Dashboard navigation and interaction elements work', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Wait for UI to settle
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test for interactive elements
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);

      // Test for navigation buttons/icons
      expect(find.byIcon(Icons.settings_rounded), findsWidgets);

      // Test for activity section elements
      expect(find.text('Recent Activity'), findsWidgets);

      // Test for quick stats section
      expect(find.text('Your Progress'), findsWidgets);

      // Test for insights section
      expect(find.text('Quick Insights'), findsWidgets);
    });

    testWidgets('Dashboard responsive design elements', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Wait for UI to settle
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test for responsive design elements
      expect(find.byType(LayoutBuilder), findsWidgets);

      // Test for grid layouts
      expect(find.byType(GridView), findsWidgets);

      // Test for proper padding and margins
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('Dashboard error handling and loading states', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Test initial loading state
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After loading, app should be stable
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
