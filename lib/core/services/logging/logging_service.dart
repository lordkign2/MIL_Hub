import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'log_level.dart';
import 'logging_config.dart';
import 'log_sanitizer.dart';

abstract class LoggingService {
  void debug(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  void info(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  void warning(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  void fatal(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  
  void log(LogLevel level, String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context});
  void setUserId(String? userId);
  void setCustomKey(String key, dynamic value);
  void addGlobalContext(Map<String, dynamic> context);
  Future<void> flush();
}

class LoggingServiceImpl implements LoggingService {
  final Logger _logger;
  final FirebaseCrashlytics _crashlytics;
  final LoggingConfig _config;
  Map<String, dynamic> _globalContext = {};

  LoggingServiceImpl({
    Logger? logger,
    FirebaseCrashlytics? crashlytics,
    LoggingConfig? config,
  })  : _logger = logger ?? _createLogger(),
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _config = config ?? LoggingConfig.currentConfig;

  static Logger _createLogger() {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: kDebugMode,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: kDebugMode ? ProductionFilter() : DevelopmentFilter(),
      output: kDebugMode ? ConsoleOutput() : MultiOutput([ConsoleOutput()]),
    );
  }

  @override
  void debug(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, error: error, stackTrace: stackTrace, context: context);
  }

  @override
  void info(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(LogLevel.info, message, error: error, stackTrace: stackTrace, context: context);
  }

  @override
  void warning(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(LogLevel.warning, message, error: error, stackTrace: stackTrace, context: context);
  }

  @override
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace, context: context);
  }

  @override
  void fatal(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(LogLevel.fatal, message, error: error, stackTrace: stackTrace, context: context);
  }

  @override
  void log(LogLevel level, String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    if (!_config.shouldLog(level)) return;

    final fullContext = <String, dynamic>{
      ..._globalContext,
      ..._config.globalContext,
      ...?context,
    };

    final sanitizedMessage = LogSanitizer.sanitizeMessage(message, _config);
    final sanitizedContext = LogSanitizer.sanitizeContext(fullContext, _config);

    if (_config.enableConsoleLogging) {
      _logToConsole(level, sanitizedMessage, error, stackTrace, sanitizedContext);
    }

    if (_config.enableCrashlyticsLogging && !kDebugMode) {
      _logToCrashlytics(level, sanitizedMessage, error, stackTrace, sanitizedContext);
    }
  }

  void _logToConsole(LogLevel level, String message, dynamic error, StackTrace? stackTrace, Map<String, dynamic> context) {
    final contextString = context.isNotEmpty ? ' | Context: $context' : '';
    final fullMessage = '$message$contextString';

    switch (level) {
      case LogLevel.debug:
        _logger.d(fullMessage, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _logger.i(fullMessage, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        _logger.w(fullMessage, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.error:
        _logger.e(fullMessage, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.fatal:
        _logger.f(fullMessage, error: error, stackTrace: stackTrace);
        break;
    }
  }

  void _logToCrashlytics(LogLevel level, String message, dynamic error, StackTrace? stackTrace, Map<String, dynamic> context) {
    final contextString = context.isNotEmpty ? ' | Context: $context' : '';
    final fullMessage = '$message$contextString';

    // Add context as custom keys
    for (final entry in context.entries) {
      _crashlytics.setCustomKey(entry.key, entry.value.toString());
    }

    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
      case LogLevel.warning:
        _crashlytics.log('${level.nameUpperCase}: $fullMessage');
        break;
      case LogLevel.error:
        _crashlytics.recordError(error ?? fullMessage, stackTrace, reason: message, fatal: false);
        break;
      case LogLevel.fatal:
        _crashlytics.recordError(error ?? fullMessage, stackTrace, reason: message, fatal: true);
        break;
    }
  }

  @override
  void setUserId(String? userId) {
    if (_config.enableCrashlyticsLogging) {
      _crashlytics.setUserIdentifier(userId ?? '');
    }
  }

  @override
  void setCustomKey(String key, dynamic value) {
    if (_config.enableCrashlyticsLogging) {
      _crashlytics.setCustomKey(key, value.toString());
    }
  }

  @override
  void addGlobalContext(Map<String, dynamic> context) {
    _globalContext.addAll(context);
  }

  @override
  Future<void> flush() async {
    // Logger doesn't have a flush method, but we can ensure Crashlytics logs are sent
    if (_config.enableCrashlyticsLogging) {
      await _crashlytics.didCrashOnPreviousExecution();
    }
  }
}
