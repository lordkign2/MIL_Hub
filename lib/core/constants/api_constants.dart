/// API endpoints and network-related constants
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://localhost:5000';
  static const String firebaseUrl = 'https://firestore.googleapis.com';

  // Admin API Endpoints
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
  static const String adminLogs = '/admin/logs';
  static const String adminCommunityStats = '/admin/community-stats';

  // User API Endpoints
  static const String userProgress = '/progress';
  static const String userProfile = '/profile';

  // Community API Endpoints
  static const String communityPosts = '/community/posts';
  static const String communityComments = '/community/comments';
  static const String communityLikes = '/community/likes';

  // Check API Endpoints
  static const String linkCheck = '/check/link';
  static const String imageCheck = '/check/image';

  // Learn API Endpoints
  static const String lessons = '/learn/lessons';
  static const String quizzes = '/learn/quizzes';
  static const String progress = '/learn/progress';

  // HTTP Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // HTTP Status Codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int serverErrorCode = 500;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'communityPosts';
  static const String commentsCollection = 'comments';
  static const String reportsCollection = 'reports';
  static const String adminActionsCollection = 'adminActions';
  static const String userStatsCollection = 'userStats';
  static const String lessonsCollection = 'lessons';
  static const String quizzesCollection = 'quizzes';
  static const String progressCollection = 'userProgress';
}
