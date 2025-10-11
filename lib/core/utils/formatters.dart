import 'package:intl/intl.dart';

/// Utility class for formatting various data types
class Formatters {
  // Date formatters
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MM/dd/yy');

  /// Format date to readable string
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time to readable string
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time to readable string
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format date to short format
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format relative time (e.g., \"2 hours ago\")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Number formatters

  /// Format number with commas
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Format number to abbreviated form (e.g., 1K, 1M)
  static String formatAbbreviatedNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toInt()}%';
  }

  /// Format decimal with specified places
  static String formatDecimal(double value, {int decimalPlaces = 2}) {
    return value.toStringAsFixed(decimalPlaces);
  }

  // Duration formatters

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Format duration in seconds to mm:ss format
  static String formatTimeFromSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // String formatters

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Convert to title case
  static String toTitleCase(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format currency
  static String formatCurrency(double amount, {String symbol = r'$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Mask email address
  static String maskEmail(String email) {
    if (email.length < 3) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  /// Mask phone number
  static String maskPhoneNumber(String phone) {
    if (phone.length < 4) return phone;
    return '***-***-${phone.substring(phone.length - 4)}';
  }

  /// Format score as grade
  static String formatGrade(double score) {
    if (score >= 0.97) return 'A+';
    if (score >= 0.93) return 'A';
    if (score >= 0.90) return 'A-';
    if (score >= 0.87) return 'B+';
    if (score >= 0.83) return 'B';
    if (score >= 0.80) return 'B-';
    if (score >= 0.77) return 'C+';
    if (score >= 0.73) return 'C';
    if (score >= 0.70) return 'C-';
    if (score >= 0.67) return 'D+';
    if (score >= 0.65) return 'D';
    return 'F';
  }
}
