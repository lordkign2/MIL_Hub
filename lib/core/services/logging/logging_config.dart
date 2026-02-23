import 'package:flutter/foundation.dart';
import 'log_level.dart';

class LoggingConfig {
  final LogLevel minimumLogLevel;
  final bool enableConsoleLogging;
  final bool enableCrashlyticsLogging;
  final bool enableFileLogging;
  final int maxLogFileSize;
  final int maxLogFiles;
  final List<String> sensitiveKeywords;
  final Map<String, dynamic> globalContext;

  const LoggingConfig({
    this.minimumLogLevel = LogLevel.debug,
    this.enableConsoleLogging = true,
    this.enableCrashlyticsLogging = true,
    this.enableFileLogging = false,
    this.maxLogFileSize = 10 * 1024 * 1024, // 10MB
    this.maxLogFiles = 5,
    this.sensitiveKeywords = const [
      'password',
      'token',
      'api_key',
      'secret',
      'credential',
      'auth',
      'session',
      'cookie',
      'ssn',
      'credit_card',
      'bank_account',
    ],
    this.globalContext = const {},
  });

  static LoggingConfig get debug => const LoggingConfig(
    minimumLogLevel: LogLevel.debug,
    enableConsoleLogging: true,
    enableCrashlyticsLogging: false,
    enableFileLogging: false,
  );

  static LoggingConfig get release => const LoggingConfig(
    minimumLogLevel: LogLevel.info,
    enableConsoleLogging: false,
    enableCrashlyticsLogging: true,
    enableFileLogging: true,
  );

  static LoggingConfig get profile => const LoggingConfig(
    minimumLogLevel: LogLevel.info,
    enableConsoleLogging: true,
    enableCrashlyticsLogging: false,
    enableFileLogging: false,
  );

  LoggingConfig copyWith({
    LogLevel? minimumLogLevel,
    bool? enableConsoleLogging,
    bool? enableCrashlyticsLogging,
    bool? enableFileLogging,
    int? maxLogFileSize,
    int? maxLogFiles,
    List<String>? sensitiveKeywords,
    Map<String, dynamic>? globalContext,
  }) {
    return LoggingConfig(
      minimumLogLevel: minimumLogLevel ?? this.minimumLogLevel,
      enableConsoleLogging: enableConsoleLogging ?? this.enableConsoleLogging,
      enableCrashlyticsLogging: enableCrashlyticsLogging ?? this.enableCrashlyticsLogging,
      enableFileLogging: enableFileLogging ?? this.enableFileLogging,
      maxLogFileSize: maxLogFileSize ?? this.maxLogFileSize,
      maxLogFiles: maxLogFiles ?? this.maxLogFiles,
      sensitiveKeywords: sensitiveKeywords ?? this.sensitiveKeywords,
      globalContext: globalContext ?? this.globalContext,
    );
  }

  bool shouldLog(LogLevel level) => level >= minimumLogLevel;

  static LoggingConfig get currentConfig {
    if (kDebugMode) return debug;
    if (kProfileMode) return profile;
    return release;
  }
}
