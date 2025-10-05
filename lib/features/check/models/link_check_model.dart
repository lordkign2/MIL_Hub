import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a link check result
class LinkCheck {
  final String id;
  final String url;
  final String originalUrl; // In case of redirects
  final bool isSafe;
  final bool isReachable;
  final String verdict;
  final List<String> suspiciousKeywords;
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  final String checkedBy; // User UID
  final DateTime createdAt;
  final String? userAgent;
  final int? responseCode;
  final Map<String, String>? headers;

  LinkCheck({
    this.id = '',
    required this.url,
    required this.originalUrl,
    required this.isSafe,
    required this.isReachable,
    required this.verdict,
    required this.suspiciousKeywords,
    required this.warnings,
    required this.metadata,
    required this.checkedBy,
    required this.createdAt,
    this.userAgent,
    this.responseCode,
    this.headers,
  });

  factory LinkCheck.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LinkCheck(
      id: doc.id,
      url: data['url'] ?? '',
      originalUrl: data['originalUrl'] ?? data['url'] ?? '',
      isSafe: data['isSafe'] ?? false,
      isReachable: data['isReachable'] ?? false,
      verdict: data['verdict'] ?? '',
      suspiciousKeywords: List<String>.from(data['suspiciousKeywords'] ?? []),
      warnings: List<String>.from(data['warnings'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      checkedBy: data['checkedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userAgent: data['userAgent'],
      responseCode: data['responseCode'],
      headers: data['headers'] != null
          ? Map<String, String>.from(data['headers'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'originalUrl': originalUrl,
      'isSafe': isSafe,
      'isReachable': isReachable,
      'verdict': verdict,
      'suspiciousKeywords': suspiciousKeywords,
      'warnings': warnings,
      'metadata': metadata,
      'checkedBy': checkedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'userAgent': userAgent,
      'responseCode': responseCode,
      'headers': headers,
    };
  }

  LinkCheck copyWith({
    String? id,
    String? url,
    String? originalUrl,
    bool? isSafe,
    bool? isReachable,
    String? verdict,
    List<String>? suspiciousKeywords,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
    String? checkedBy,
    DateTime? createdAt,
    String? userAgent,
    int? responseCode,
    Map<String, String>? headers,
  }) {
    return LinkCheck(
      id: id ?? this.id,
      url: url ?? this.url,
      originalUrl: originalUrl ?? this.originalUrl,
      isSafe: isSafe ?? this.isSafe,
      isReachable: isReachable ?? this.isReachable,
      verdict: verdict ?? this.verdict,
      suspiciousKeywords: suspiciousKeywords ?? this.suspiciousKeywords,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
      checkedBy: checkedBy ?? this.checkedBy,
      createdAt: createdAt ?? this.createdAt,
      userAgent: userAgent ?? this.userAgent,
      responseCode: responseCode ?? this.responseCode,
      headers: headers ?? this.headers,
    );
  }
}

/// Enum for different types of checks performed
enum CheckType {
  protocol,
  keywords,
  reachability,
  factCheck, // Google Fact Check Tools API
  newsCredibility, // News source credibility check
  // Future expansion points for advanced checks
  safeBrowsing, // Google Safe Browsing API
  whois, // Domain registration info
  aiSentiment, // AI-powered content analysis
  socialSignals, // Social media reputation
}

/// Result model for individual check types
class CheckResult {
  final CheckType type;
  final bool passed;
  final String message;
  final String? details;
  final Map<String, dynamic>? data;

  CheckResult({
    required this.type,
    required this.passed,
    required this.message,
    this.details,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'passed': passed,
      'message': message,
      'details': details,
      'data': data,
    };
  }
}

/// Overall assessment of a link
class LinkAssessment {
  final String url;
  final List<CheckResult> results;
  final bool isOverallSafe;
  final String verdict;
  final double confidence;
  final List<String> recommendations;

  LinkAssessment({
    required this.url,
    required this.results,
    required this.isOverallSafe,
    required this.verdict,
    required this.confidence,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'results': results.map((r) => r.toJson()).toList(),
      'isOverallSafe': isOverallSafe,
      'verdict': verdict,
      'confidence': confidence,
      'recommendations': recommendations,
    };
  }
}
