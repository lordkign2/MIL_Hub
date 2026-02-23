import 'logging_service.dart';
import 'log_level.dart';

extension LoggingExtensions on LoggingService {
  /// Log method execution time
  Future<T> logExecutionTime<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? context,
    LogLevel level = LogLevel.info,
  }) async {
    final stopwatch = Stopwatch()..start();
    final operationContext = {
      'operation': operationName,
      ...?context,
    };
    
    try {
      log(level, 'Starting $operationName', context: operationContext);
      final result = await operation();
      stopwatch.stop();
      
      log(
        level,
        'Completed $operationName in ${stopwatch.elapsedMilliseconds}ms',
        context: {
          ...operationContext,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'success': true,
        },
      );
      
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      
      this.error(
        'Failed $operationName after ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
        context: {
          ...operationContext,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'success': false,
        },
      );
      
      rethrow;
    }
  }

  /// Log user action
  void logUserAction(
    String action, {
    Map<String, dynamic>? parameters,
    String? screen,
    LogLevel level = LogLevel.info,
  }) {
    log(
      level,
      'User action: $action',
      context: {
        'user_action': action,
        'screen': screen,
        ...?parameters,
      },
    );
  }

  /// Log network request
  void logNetworkRequest(
    String method,
    String url, {
    int? statusCode,
    int? responseTime,
    dynamic error,
    Map<String, dynamic>? additionalContext,
    LogLevel level = LogLevel.info,
  }) {
    final context = {
      'method': method,
      'url': url,
      if (statusCode != null) 'status_code': statusCode,
      if (responseTime != null) 'response_time_ms': responseTime,
      ...?additionalContext,
    };

    if (error != null) {
      this.error(
        'Network request failed: $method $url',
        error: error,
        context: context,
      );
    } else {
      log(
        level,
        'Network request: $method $url',
        context: context,
      );
    }
  }

  /// Log performance metrics
  void logPerformance(
    String metricName,
    dynamic value, {
    String? unit,
    Map<String, dynamic>? context,
  }) {
    log(
      LogLevel.info,
      'Performance metric: $metricName = $value${unit != null ? ' $unit' : ''}',
      context: {
        'metric_name': metricName,
        'metric_value': value,
        if (unit != null) 'metric_unit': unit,
        ...?context,
      },
    );
  }

  /// Log business event
  void logBusinessEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    LogLevel level = LogLevel.info,
  }) {
    log(
      level,
      'Business event: $eventName',
      context: {
        'event_name': eventName,
        'event_type': 'business',
        ...?properties,
      },
    );
  }

  /// Log security event
  void logSecurityEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    LogLevel level = LogLevel.warning,
  }) {
    log(
      level,
      'Security event: $eventName',
      context: {
        'event_name': eventName,
        'event_type': 'security',
        ...?properties,
      },
    );
  }
}
