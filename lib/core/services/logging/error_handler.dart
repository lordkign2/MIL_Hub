import 'dart:async';
import 'package:flutter/foundation.dart';
import 'logging_service.dart';
import 'log_level.dart';

class ErrorHandler {
  final LoggingService _loggingService;
  
  ErrorHandler(this._loggingService);

  /// Handle and log exceptions with context
  void handleException(
    Exception exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool shouldRethrow = false,
    LogLevel level = LogLevel.error,
  }) {
    _loggingService.log(
      level,
      'Exception handled: ${exception.runtimeType}',
      error: exception,
      stackTrace: stackTrace,
      context: context,
    );

    if (shouldRethrow) {
      throw exception;
    }
  }

  /// Handle and log errors with context
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool shouldRethrow = false,
    LogLevel level = LogLevel.error,
  }) {
    _loggingService.log(
      level,
      'Error handled: ${error.runtimeType}',
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    if (shouldRethrow) {
      throw error;
    }
  }

  /// Wrap a function with error handling
  T withErrorHandling<T>(
    T Function() function, {
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.error,
    String? operationName,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      _loggingService.log(
        level,
        'Error in ${operationName ?? 'operation'}',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
      rethrow;
    }
  }

  /// Wrap an async function with error handling
  Future<T> withAsyncErrorHandling<T>(
    Future<T> Function() function, {
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.error,
    String? operationName,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      _loggingService.log(
        level,
        'Async error in ${operationName ?? 'operation'}',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
      rethrow;
    }
  }

  /// Handle stream errors
  Stream<T> handleStreamErrors<T>(
    Stream<T> stream, {
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.error,
    String? streamName,
  }) {
    return stream.handleError(
      (error, stackTrace) {
        _loggingService.log(
          level,
          'Stream error in ${streamName ?? 'stream'}',
          error: error,
          stackTrace: stackTrace,
          context: context,
        );
      },
    );
  }

  /// Handle future errors
  Future<T> handleFutureErrors<T>(
    Future<T> future, {
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.error,
    String? futureName,
  }) {
    return future.catchError(
      (error, stackTrace) {
        _loggingService.log(
          level,
          'Future error in ${futureName ?? 'future'}',
          error: error,
          stackTrace: stackTrace,
          context: context,
        );
        throw error; // Re-throw to maintain original behavior
      },
    );
  }

  /// Set up global error handlers
  void setupGlobalErrorHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _loggingService.fatal(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
        context: {
          'error_type': 'flutter_framework',
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };

    // Handle uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _loggingService.fatal(
        'Uncaught async error',
        error: error,
        stackTrace: stack,
        context: {'error_type': 'uncaught_async'},
      );
      return true;
    };
  }

  /// Create a safe zone with error handling
  SafeErrorZone createSafeZone({
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.error,
    String? zoneName,
  }) {
    return SafeErrorZone(
      _loggingService,
      context: context,
      level: level,
      zoneName: zoneName,
    );
  }
}

class SafeErrorZone {
  final LoggingService _loggingService;
  final Map<String, dynamic>? context;
  final LogLevel level;
  final String? zoneName;

  SafeErrorZone(
    this._loggingService, {
    this.context,
    this.level = LogLevel.error,
    this.zoneName,
  });

  /// Execute code within a safe error zone
  T execute<T>(
    T Function() function, {
    T? fallback,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      _loggingService.log(
        level,
        'Error in safe zone ${zoneName ?? 'unnamed'}',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
      return fallback as T;
    }
  }

  /// Execute async code within a safe error zone
  Future<T> executeAsync<T>(
    Future<T> Function() function, {
    T? fallback,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      _loggingService.log(
        level,
        'Async error in safe zone ${zoneName ?? 'unnamed'}',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
      return fallback as T;
    }
  }
}
