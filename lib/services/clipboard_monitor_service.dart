import 'package:flutter/services.dart';

class ClipboardMonitorService {
  static String? _lastCheckedClipboard;

  /// Checks clipboard content when app becomes active
  /// Returns true if suspicious content is detected
  static Future<ClipboardCheckResult?> checkClipboardOnResume() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final clipboardText = clipboardData?.text?.trim();

      // Skip if no content or same as last checked
      if (clipboardText == null ||
          clipboardText.isEmpty ||
          clipboardText == _lastCheckedClipboard) {
        return null;
      }

      _lastCheckedClipboard = clipboardText;

      // Check if content contains URL
      final isUrl = _isUrl(clipboardText);

      // Check for suspicious keywords
      final suspiciousKeywords = _findSuspiciousKeywords(clipboardText);

      // Only show dialog if URL or suspicious content detected
      if (isUrl || suspiciousKeywords.isNotEmpty) {
        return ClipboardCheckResult(
          content: clipboardText,
          isUrl: isUrl,
          suspiciousKeywords: suspiciousKeywords,
          shouldShowDialog: true,
        );
      }

      return null;
    } catch (e) {
      // Silently handle clipboard access errors
      return null;
    }
  }

  /// Checks if text contains a URL
  static bool _isUrl(String text) {
    final urlRegex = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+\.[a-z]{2,}|[a-zA-Z0-9\-]+\.[a-z]{2,}\/[^\s]*)',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text);
  }

  /// Finds suspicious keywords in text
  static List<String> _findSuspiciousKeywords(String text) {
    // Use the same suspicious keywords from LinkCheckService
    const suspiciousKeywords = [
      'free',
      'giveaway',
      'prize',
      'urgent',
      'limited time',
      'act now',
      'click here',
      'winner',
      'congratulations',
      'claim now',
      'exclusive',
      'offer expires',
      'shocking',
      'unbelievable',
      'miracle',
      'guaranteed',
      'risk-free',
      'no credit check',
      'easy money',
      'work from home',
      'get rich quick',
      'lose weight fast',
      'secret revealed',
      'doctors hate this',
      'one weird trick',
      'credit card',
      'personal information',
      'verify account',
      'suspended account',
      'confirm identity',
      'download now',
      'install app',
    ];

    final foundKeywords = <String>[];
    final lowerText = text.toLowerCase();

    for (final keyword in suspiciousKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        foundKeywords.add(keyword);
      }
    }

    return foundKeywords;
  }

  /// Resets the last checked clipboard (useful for testing)
  static void resetLastChecked() {
    _lastCheckedClipboard = null;
  }
}

class ClipboardCheckResult {
  final String content;
  final bool isUrl;
  final List<String> suspiciousKeywords;
  final bool shouldShowDialog;

  ClipboardCheckResult({
    required this.content,
    required this.isUrl,
    required this.suspiciousKeywords,
    required this.shouldShowDialog,
  });

  bool get isSuspicious =>
      suspiciousKeywords.isNotEmpty || (isUrl && _hasRiskIndicators);

  bool get _hasRiskIndicators {
    if (!isUrl) return false;

    final lowerContent = content.toLowerCase();

    // Check for risky URL patterns
    final riskPatterns = [
      'bit.ly',
      'tinyurl',
      'goo.gl',
      't.co',
      'ow.ly',
      'shortened',
      'redirect',
      'click-here',
      'free-download',
      'urgent-action',
    ];

    return riskPatterns.any((pattern) => lowerContent.contains(pattern));
  }

  String get warningMessage {
    if (isUrl && suspiciousKeywords.isNotEmpty) {
      return 'Suspicious URL detected with keywords: ${suspiciousKeywords.take(3).join(', ')}';
    } else if (isUrl) {
      return 'URL detected in clipboard';
    } else if (suspiciousKeywords.isNotEmpty) {
      return 'Suspicious content detected with keywords: ${suspiciousKeywords.take(3).join(', ')}';
    }
    return 'Suspicious content detected';
  }

  String get recommendationMessage {
    if (isUrl) {
      return 'Would you like to check this link for safety before opening it?';
    }
    return 'This content may be suspicious. Exercise caution if you received this from an unknown source.';
  }
}
