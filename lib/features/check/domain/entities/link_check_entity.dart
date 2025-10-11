import 'package:equatable/equatable.dart';

/// Entity representing a link check result
class LinkCheckEntity extends Equatable {
  final String id;
  final String url;
  final String originalUrl;
  final bool isSafe;
  final bool isReachable;
  final String verdict;
  final List<String> suspiciousKeywords;
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  final String checkedBy;
  final DateTime createdAt;
  final String? userAgent;
  final int? responseCode;
  final Map<String, String>? headers;

  const LinkCheckEntity({
    required this.id,
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

  @override
  List<Object?> get props => [
    id,
    url,
    originalUrl,
    isSafe,
    isReachable,
    verdict,
    suspiciousKeywords,
    warnings,
    metadata,
    checkedBy,
    createdAt,
    userAgent,
    responseCode,
    headers,
  ];
}

/// Enum for different types of checks performed
enum CheckType {
  protocol,
  keywords,
  reachability,
  factCheck,
  newsCredibility,
  safeBrowsing,
  whois,
  aiSentiment,
  socialSignals,
}

/// Result entity for individual check types
class CheckResultEntity extends Equatable {
  final CheckType type;
  final bool passed;
  final String message;
  final String? details;
  final Map<String, dynamic>? data;

  const CheckResultEntity({
    required this.type,
    required this.passed,
    required this.message,
    this.details,
    this.data,
  });

  @override
  List<Object?> get props => [type, passed, message, details, data];

  CheckResultEntity copyWith({
    CheckType? type,
    bool? passed,
    String? message,
    String? details,
    Map<String, dynamic>? data,
  }) {
    return CheckResultEntity(
      type: type ?? this.type,
      passed: passed ?? this.passed,
      message: message ?? this.message,
      details: details ?? this.details,
      data: data ?? this.data,
    );
  }
}

/// Overall assessment entity of a link
class LinkAssessmentEntity extends Equatable {
  final String url;
  final List<CheckResultEntity> results;
  final bool isOverallSafe;
  final String verdict;
  final double confidence;
  final List<String> recommendations;

  const LinkAssessmentEntity({
    required this.url,
    required this.results,
    required this.isOverallSafe,
    required this.verdict,
    required this.confidence,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
    url,
    results,
    isOverallSafe,
    verdict,
    confidence,
    recommendations,
  ];

  LinkAssessmentEntity copyWith({
    String? url,
    List<CheckResultEntity>? results,
    bool? isOverallSafe,
    String? verdict,
    double? confidence,
    List<String>? recommendations,
  }) {
    return LinkAssessmentEntity(
      url: url ?? this.url,
      results: results ?? this.results,
      isOverallSafe: isOverallSafe ?? this.isOverallSafe,
      verdict: verdict ?? this.verdict,
      confidence: confidence ?? this.confidence,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

/// Entity for image authenticity check
class ImageAuthenticityEntity extends Equatable {
  final bool isAuthentic;
  final double confidence;
  final String verdict;
  final String summary;
  final List<ImageSearchResultEntity> searchResults;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const ImageAuthenticityEntity({
    required this.isAuthentic,
    required this.confidence,
    required this.verdict,
    required this.summary,
    required this.searchResults,
    required this.warnings,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
    isAuthentic,
    confidence,
    verdict,
    summary,
    searchResults,
    warnings,
    metadata,
  ];

  ImageAuthenticityEntity copyWith({
    bool? isAuthentic,
    double? confidence,
    String? verdict,
    String? summary,
    List<ImageSearchResultEntity>? searchResults,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return ImageAuthenticityEntity(
      isAuthentic: isAuthentic ?? this.isAuthentic,
      confidence: confidence ?? this.confidence,
      verdict: verdict ?? this.verdict,
      summary: summary ?? this.summary,
      searchResults: searchResults ?? this.searchResults,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Entity for image search result
class ImageSearchResultEntity extends Equatable {
  final String apiSource;
  final int totalMatches;
  final List<ImageMatchEntity> matches;
  final Duration processingTime;
  final String status;

  const ImageSearchResultEntity({
    required this.apiSource,
    required this.totalMatches,
    required this.matches,
    required this.processingTime,
    required this.status,
  });

  @override
  List<Object?> get props => [
    apiSource,
    totalMatches,
    matches,
    processingTime,
    status,
  ];

  ImageSearchResultEntity copyWith({
    String? apiSource,
    int? totalMatches,
    List<ImageMatchEntity>? matches,
    Duration? processingTime,
    String? status,
  }) {
    return ImageSearchResultEntity(
      apiSource: apiSource ?? this.apiSource,
      totalMatches: totalMatches ?? this.totalMatches,
      matches: matches ?? this.matches,
      processingTime: processingTime ?? this.processingTime,
      status: status ?? this.status,
    );
  }
}

/// Entity for individual image match
class ImageMatchEntity extends Equatable {
  final String sourceUrl;
  final String thumbnailUrl;
  final String hostPageUrl;
  final String title;
  final String description;
  final double confidence;
  final DateTime dateFound;
  final int width;
  final int height;

  const ImageMatchEntity({
    required this.sourceUrl,
    required this.thumbnailUrl,
    required this.hostPageUrl,
    required this.title,
    required this.description,
    required this.confidence,
    required this.dateFound,
    required this.width,
    required this.height,
  });

  @override
  List<Object?> get props => [
    sourceUrl,
    thumbnailUrl,
    hostPageUrl,
    title,
    description,
    confidence,
    dateFound,
    width,
    height,
  ];

  ImageMatchEntity copyWith({
    String? sourceUrl,
    String? thumbnailUrl,
    String? hostPageUrl,
    String? title,
    String? description,
    double? confidence,
    DateTime? dateFound,
    int? width,
    int? height,
  }) {
    return ImageMatchEntity(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hostPageUrl: hostPageUrl ?? this.hostPageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      dateFound: dateFound ?? this.dateFound,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
