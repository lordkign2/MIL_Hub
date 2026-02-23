import 'logging_config.dart';

class LogSanitizer {
  static String sanitizeMessage(String message, LoggingConfig config) {
    String sanitized = message;

    // Remove sensitive information
    for (final keyword in config.sensitiveKeywords) {
      final pattern = RegExp('$keyword[\\s]*[=:][\\s]*[^\\s,}]+', caseSensitive: false);
      sanitized = sanitized.replaceAll(pattern, '$keyword=***REDACTED***');
    }

    // Remove potential email addresses
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    sanitized = sanitized.replaceAll(emailPattern, '***EMAIL***');

    // Remove phone numbers (basic pattern)
    final phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    sanitized = sanitized.replaceAll(phonePattern, '***PHONE***');

    // Remove credit card numbers (basic pattern)
    final creditCardPattern = RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b');
    sanitized = sanitized.replaceAll(creditCardPattern, '***CARD***');

    // Remove JWT tokens (basic pattern)
    final jwtPattern = RegExp(r'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*');
    sanitized = sanitized.replaceAll(jwtPattern, '***TOKEN***');

    return sanitized;
  }

  static Map<String, dynamic> sanitizeContext(Map<String, dynamic> context, LoggingConfig config) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in context.entries) {
      if (_isSensitiveKey(entry.key, config)) {
        sanitized[entry.key] = '***REDACTED***';
      } else if (entry.value is String) {
        sanitized[entry.key] = sanitizeMessage(entry.value.toString(), config);
      } else if (entry.value is Map) {
        sanitized[entry.key] = sanitizeContext(Map<String, dynamic>.from(entry.value), config);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  static bool _isSensitiveKey(String key, LoggingConfig config) {
    final lowerKey = key.toLowerCase();
    return config.sensitiveKeywords.any((keyword) => lowerKey.contains(keyword));
  }
}
