import 'package:flutter/foundation.dart';
import 'package:mil_hub/core/di/injection_container.dart';
import 'package:mil_hub/core/services/logging/logging_facade.dart';
import 'package:mil_hub/core/services/logging/log_level.dart';

/// Examples demonstrating how to use the comprehensive logging system
class LoggingExamples {
  final LoggingService _logger = sl<LoggingService>();
  final ErrorHandler _errorHandler = sl<ErrorHandler>();

  /// Example 1: Basic logging with context
  void basicLoggingExample() {
    // Debug logging - only shown in debug mode
    _logger.debug(
      'User data loaded from cache',
      context: {
        'user_id': 'user_123',
        'cache_size': '2.5MB',
        'load_time_ms': 45,
      },
    );

    // Info logging - shown in debug and release
    _logger.info(
      'User authentication successful',
      context: {
        'user_id': 'user_123',
        'auth_method': 'google_sign_in',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Warning logging - potential issues
    _logger.warning(
      'API rate limit approaching',
      context: {
        'current_requests': 95,
        'limit': 100,
        'reset_time': '2024-01-01T12:00:00Z',
      },
    );

    // Error logging - recoverable errors
    try {
      throw Exception('Network connection failed');
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to sync user data',
        error: error,
        stackTrace: stackTrace,
        context: {
          'user_id': 'user_123',
          'retry_count': 3,
          'last_sync': '2024-01-01T10:30:00Z',
        },
      );
    }
  }

  /// Example 2: Performance monitoring
  Future<void> performanceMonitoringExample() async {
    // Monitor execution time
    final result = await _logger.logExecutionTime(
      'database_query',
      () async {
        // Simulate database operation
        await Future.delayed(Duration(milliseconds: 250));
        return {'users': ['user1', 'user2', 'user3']};
      },
      context: {
        'query_type': 'select_users',
        'table': 'users',
        'limit': 10,
      },
    );

    // Log performance metrics
    _logger.logPerformance(
      'memory_usage',
      125.6,
      unit: 'MB',
      context: {
        'screen': 'user_list',
        'total_users': 1000,
      },
    );

    _logger.logPerformance(
      'frame_rate',
      58.5,
      unit: 'fps',
      context: {
        'screen': 'user_list',
        'animation': 'scroll',
      },
    );
  }

  /// Example 3: User action tracking
  void userActionTrackingExample() {
    // Track button clicks
    _logger.logUserAction(
      'button_clicked',
      parameters: {
        'button_id': 'submit_form',
        'button_text': 'Submit',
        'form_type': 'registration',
      },
      screen: 'registration',
    );

    // Track navigation
    _logger.logUserAction(
      'navigation',
      parameters: {
        'from_screen': 'login',
        'to_screen': 'dashboard',
        'navigation_method': 'bottom_nav',
      },
      screen: 'login',
    );

    // Track feature usage
    _logger.logUserAction(
      'feature_used',
      parameters: {
        'feature_name': 'link_checker',
        'feature_version': '2.1.0',
        'usage_duration_ms': 1200,
      },
      screen: 'link_checker',
    );
  }

  /// Example 4: Network request logging
  void networkLoggingExample() {
    // Successful request
    _logger.logNetworkRequest(
      'GET',
      'https://api.example.com/users',
      statusCode: 200,
      responseTime: 250,
      context: {
        'endpoint': 'users',
        'cache_hit': false,
        'response_size_bytes': 1024,
      },
    );

    // Failed request
    _logger.logNetworkRequest(
      'POST',
      'https://api.example.com/users',
      statusCode: 400,
      responseTime: 150,
      error: 'Invalid user data',
      context: {
        'endpoint': 'users',
        'request_size_bytes': 512,
        'validation_errors': ['invalid_email', 'weak_password'],
      },
    );
  }

  /// Example 5: Business event logging
  void businessEventLoggingExample() {
    // User registration
    _logger.logBusinessEvent(
      'user_registered',
      properties: {
        'user_id': 'user_123',
        'registration_method': 'email',
        'user_type': 'student',
        'referral_source': 'social_media',
      },
    );

    // Content interaction
    _logger.logBusinessEvent(
      'content_completed',
      properties: {
        'content_id': 'lesson_456',
        'content_type': 'video_lesson',
        'completion_percentage': 100,
        'time_spent_minutes': 15,
      },
    );

    // Achievement unlocked
    _logger.logBusinessEvent(
      'achievement_unlocked',
      properties: {
        'achievement_id': 'first_fact_check',
        'achievement_type': 'milestone',
        'user_level': 3,
      },
    );
  }

  /// Example 6: Security event logging
  void securityEventLoggingExample() {
    // Failed login attempt
    _logger.logSecurityEvent(
      'failed_login_attempt',
      properties: {
        'email': 'user@example.com',
        'failure_reason': 'invalid_password',
        'ip_address': '192.168.1.100',
        'user_agent': 'Mozilla/5.0...',
      },
    );

    // Suspicious activity
    _logger.logSecurityEvent(
      'suspicious_activity',
      properties: {
        'activity_type': 'multiple_failed_attempts',
        'attempt_count': 5,
        'time_window_minutes': 2,
        'ip_address': '192.168.1.100',
      },
    );
  }

  /// Example 7: Error handling with ErrorHandler
  Future<void> errorHandlingExample() async {
    // Wrap risky operations
    final result = _errorHandler.withErrorHandling(
      () => riskyOperation(),
      context: {
        'operation': 'data_processing',
        'input_size': 1000,
      },
    );

    // Async error handling
    final asyncResult = await _errorHandler.withAsyncErrorHandling(
      () async => await riskyAsyncOperation(),
      context: {
        'operation': 'api_call',
        'endpoint': '/users',
      },
    );

    // Safe zones
    final safeZone = _errorHandler.createSafeZone(
      zoneName: 'ui_operations',
      context: {'screen': 'dashboard'},
    );

    final safeResult = safeZone.execute(
      () => uiOperation(),
      fallback: defaultValue,
    );

    final safeAsyncResult = await safeZone.executeAsync(
      () async => await asyncUiOperation(),
      fallback: asyncDefaultValue,
    );
  }

  /// Example 8: Global context and user identification
  void globalContextExample() {
    // Set user identifier for Crashlytics
    _logger.setUserId('user_123');

    // Add global context to all logs
    _logger.addGlobalContext({
      'session_id': 'session_456',
      'app_version': '1.0.0',
      'device_type': 'mobile',
      'connection_type': 'wifi',
    });

    // Set custom keys for Crashlytics
    _logger.setCustomKey('user_tier', 'premium');
    _logger.setCustomKey('feature_flags', 'link_checker,advanced_search');

    // Now all logs will include this context
    _logger.info('User performed action'); // Will include global context
  }

  /// Example 9: Privacy-aware logging
  void privacyLoggingExample() {
    // This will automatically sanitize sensitive data
    _logger.info('User login attempt', context: {
      'email': 'user@example.com', // Will be sanitized to ***EMAIL***
      'password': 'secret123', // Will be sanitized to password=***REDACTED***
      'api_key': 'sk-1234567890', // Will be sanitized
      'user_id': 'user_123', // This is safe and will be logged
    });

    // Custom sensitive keywords can be added to the config
    _logger.info('Payment processing', context: {
      'credit_card': '4111-1111-1111-1111', // Will be sanitized
      'amount': 99.99, // This is safe
      'currency': 'USD', // This is safe
    });
  }

  /// Example 10: Build-specific behavior
  void buildSpecificExample() {
    if (kDebugMode) {
      // Debug mode - verbose logging with emojis and colors
      _logger.debug('Debug information with detailed context');
      _logger.info('Info message for developers');
    } else {
      // Release mode - only important logs go to Crashlytics
      _logger.info('Important user action');
      _logger.error('Critical error that needs investigation');
    }

    // The logging service automatically handles build differences
    _logger.debug('This will only appear in debug builds');
    _logger.error('This will appear in all builds (console in debug, Crashlytics in release)');
  }

  // Helper methods for examples
  dynamic riskyOperation() {
    throw Exception('Something went wrong');
  }

  Future<dynamic> riskyAsyncOperation() async {
    await Future.delayed(Duration(milliseconds: 100));
    throw Exception('Async operation failed');
  }

  dynamic uiOperation() {
    return 'UI operation result';
  }

  Future<dynamic> asyncUiOperation() async {
    await Future.delayed(Duration(milliseconds: 50));
    return 'Async UI operation result';
  }

  static const defaultValue = 'default_value';
  static const asyncDefaultValue = 'async_default_value';
}
