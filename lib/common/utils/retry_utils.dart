import 'dart:async';
import 'dart:math';

/// Utility class for implementing retry mechanisms with exponential backoff
class RetryUtils {
  /// Executes a function with retry logic and exponential backoff
  ///
  /// [operation] - The async function to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay between retries in milliseconds (default: 1000)
  /// [maxDelay] - Maximum delay between retries in milliseconds (default: 10000)
  /// [backoffMultiplier] - Multiplier for exponential backoff (default: 2.0)
  /// [onRetry] - Callback function called on each retry attempt
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    double backoffMultiplier = 2.0,
    Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    int delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // If we've reached max retries, rethrow the error
        if (attempt > maxRetries) {
          rethrow;
        }

        // Call retry callback if provided
        if (onRetry != null) {
          onRetry(attempt, error);
        }

        // Calculate next delay with exponential backoff and jitter
        final nextDelay = min(delay, maxDelay);
        final jitter = Random().nextInt(nextDelay ~/ 2);
        final actualDelay = nextDelay + jitter;

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: actualDelay));

        // Update delay for next iteration
        delay = (delay * backoffMultiplier).toInt();
      }
    }
  }

  /// Executes a function with retry logic and fixed delay
  ///
  /// [operation] - The async function to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [fixedDelay] - Fixed delay between retries in milliseconds (default: 1000)
  /// [onRetry] - Callback function called on each retry attempt
  static Future<T> retryWithFixedDelay<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    int fixedDelay = 1000,
    Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // If we've reached max retries, rethrow the error
        if (attempt > maxRetries) {
          rethrow;
        }

        // Call retry callback if provided
        if (onRetry != null) {
          onRetry(attempt, error);
        }

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: fixedDelay));
      }
    }
  }

  /// Checks if an error is retryable based on common patterns
  ///
  /// [error] - The error to check
  /// [customRetryableErrors] - Additional error types to consider retryable
  static bool isRetryableError(
    Object error, [
    List<Type>? customRetryableErrors,
  ]) {
    // Common retryable error types
    final retryableTypes = [
      'TimeoutException',
      'SocketException',
      'HttpException',
      'ConnectionException',
      // Add custom retryable errors if provided
      ...(customRetryableErrors?.map((e) => e.toString()) ?? []),
    ];

    // Check if error message contains common retryable patterns
    final errorMessage = error.toString().toLowerCase();
    final retryablePatterns = [
      'timeout',
      'network',
      'connection',
      'socket',
      'http',
      'server error',
      'temporary failure',
    ];

    // Check if error type is retryable
    if (retryableTypes.contains(error.runtimeType.toString())) {
      return true;
    }

    // Check if error message contains retryable patterns
    for (final pattern in retryablePatterns) {
      if (errorMessage.contains(pattern)) {
        return true;
      }
    }

    return false;
  }
}
