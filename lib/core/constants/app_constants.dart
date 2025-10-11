/// Application-wide constants used throughout the MIL Hub app
class AppConstants {
  // App Information
  static const String appName = 'MIL Hub';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Media Information Literacy Hub';

  // Routes
  static const String landingRoute = '/landing';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String dashboardRoute = '/dashboard';
  static const String linkCheckRoute = '/link-check';
  static const String shareCheckRoute = '/share-check';

  // Feature Routes
  static const String learnRoute = '/learn';
  static const String communityRoute = '/community';
  static const String checkRoute = '/check';
  static const String adminRoute = '/admin';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);

  // UI Constants
  static const double defaultPadding = 20.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 32.0;
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  // Network
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;

  // File Upload
  static const int maxImageSizeInMB = 5;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection';
  static const String serverErrorMessage =
      'Something went wrong. Please try again later';
  static const String authErrorMessage =
      'Authentication failed. Please login again';
}
