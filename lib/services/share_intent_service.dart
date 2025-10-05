import 'dart:async';
import 'package:flutter/material.dart';
// Note: receive_sharing_intent temporarily removed due to JVM compatibility issues
// Will be re-implemented using platform channels or alternative solution

class SharedMediaFile {
  final String path;
  final String? type;

  SharedMediaFile(this.path, {this.type});
}

class ShareIntentService {
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the share intent service
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    // Note: We'll implement this step by step to ensure compatibility
    debugPrint('ShareIntentService initialized');
  }

  /// Clean up listeners
  static void dispose() {
    // Cleanup when needed
    debugPrint('ShareIntentService disposed');
  }

  /// Navigate to the share check screen - This is the core functionality we need
  static void navigateToShareCheck(
    String content,
    ShareContentType type, {
    SharedMediaFile? fileInfo,
  }) {
    if (_navigatorKey?.currentContext == null) {
      // If navigator is not ready, wait and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToShareCheck(content, type, fileInfo: fileInfo);
      });
      return;
    }

    // Navigate to share check screen
    _navigatorKey!.currentState?.pushNamed(
      '/share-check',
      arguments: ShareCheckArguments(
        content: content,
        type: type,
        fileInfo: fileInfo,
      ),
    );
  }

  /// Extract URLs from text content
  static List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+\.[a-z]{2,}|[a-zA-Z0-9\-]+\.[a-z]{2,}\/[^\s]*)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  /// Clean and validate URL
  static String cleanUrl(String url) {
    url = url.trim();

    // Remove common prefixes that might be included
    if (url.startsWith('Check out this link: ')) {
      url = url.substring('Check out this link: '.length);
    }

    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    return url;
  }
}

/// Types of shared content
enum ShareContentType { text, file, url }

/// Arguments for share check screen
class ShareCheckArguments {
  final String content;
  final ShareContentType type;
  final SharedMediaFile? fileInfo;

  const ShareCheckArguments({
    required this.content,
    required this.type,
    this.fileInfo,
  });

  /// Check if content contains URLs
  bool get hasUrls => ShareIntentService.extractUrls(content).isNotEmpty;

  /// Get the first URL if any
  String? get firstUrl {
    final urls = ShareIntentService.extractUrls(content);
    return urls.isNotEmpty ? ShareIntentService.cleanUrl(urls.first) : null;
  }

  /// Get all URLs in content
  List<String> get allUrls {
    return ShareIntentService.extractUrls(
      content,
    ).map((url) => ShareIntentService.cleanUrl(url)).toList();
  }
}
