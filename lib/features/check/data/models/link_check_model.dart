import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/link_check_entity.dart';

/// Model representing a link check result
class LinkCheckModel extends LinkCheckEntity {
  const LinkCheckModel({
    required super.id,
    required super.url,
    required super.originalUrl,
    required super.isSafe,
    required super.isReachable,
    required super.verdict,
    required super.suspiciousKeywords,
    required super.warnings,
    required super.metadata,
    required super.checkedBy,
    required super.createdAt,
    super.userAgent,
    super.responseCode,
    super.headers,
  });

  factory LinkCheckModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LinkCheckModel(
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

  factory LinkCheckModel.fromEntity(LinkCheckEntity entity) {
    return LinkCheckModel(
      id: entity.id,
      url: entity.url,
      originalUrl: entity.originalUrl,
      isSafe: entity.isSafe,
      isReachable: entity.isReachable,
      verdict: entity.verdict,
      suspiciousKeywords: entity.suspiciousKeywords,
      warnings: entity.warnings,
      metadata: entity.metadata,
      checkedBy: entity.checkedBy,
      createdAt: entity.createdAt,
      userAgent: entity.userAgent,
      responseCode: entity.responseCode,
      headers: entity.headers,
    );
  }

  LinkCheckEntity toEntity() {
    return LinkCheckEntity(
      id: id,
      url: url,
      originalUrl: originalUrl,
      isSafe: isSafe,
      isReachable: isReachable,
      verdict: verdict,
      suspiciousKeywords: suspiciousKeywords,
      warnings: warnings,
      metadata: metadata,
      checkedBy: checkedBy,
      createdAt: createdAt,
      userAgent: userAgent,
      responseCode: responseCode,
      headers: headers,
    );
  }
}

/// Result model for individual check types
class CheckResultModel extends CheckResultEntity {
  const CheckResultModel({
    required super.type,
    required super.passed,
    required super.message,
    super.details,
    super.data,
  });

  factory CheckResultModel.fromEntity(CheckResultEntity entity) {
    return CheckResultModel(
      type: entity.type,
      passed: entity.passed,
      message: entity.message,
      details: entity.details,
      data: entity.data,
    );
  }

  CheckResultEntity toEntity() {
    return CheckResultEntity(
      type: type,
      passed: passed,
      message: message,
      details: details,
      data: data,
    );
  }

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
class LinkAssessmentModel extends LinkAssessmentEntity {
  const LinkAssessmentModel({
    required super.url,
    required super.results,
    required super.isOverallSafe,
    required super.verdict,
    required super.confidence,
    required super.recommendations,
  });

  factory LinkAssessmentModel.fromEntity(LinkAssessmentEntity entity) {
    return LinkAssessmentModel(
      url: entity.url,
      results: entity.results
          .map((result) => CheckResultModel.fromEntity(result))
          .toList(),
      isOverallSafe: entity.isOverallSafe,
      verdict: entity.verdict,
      confidence: entity.confidence,
      recommendations: entity.recommendations,
    );
  }

  LinkAssessmentEntity toEntity() {
    return LinkAssessmentEntity(
      url: url,
      results: results.map((result) => result.copyWith()).toList(),
      isOverallSafe: isOverallSafe,
      verdict: verdict,
      confidence: confidence,
      recommendations: recommendations,
    );
  }
}

/// Model for image authenticity check
class ImageAuthenticityModel extends ImageAuthenticityEntity {
  const ImageAuthenticityModel({
    required super.isAuthentic,
    required super.confidence,
    required super.verdict,
    required super.summary,
    required super.searchResults,
    required super.warnings,
    required super.metadata,
  });

  factory ImageAuthenticityModel.fromEntity(ImageAuthenticityEntity entity) {
    return ImageAuthenticityModel(
      isAuthentic: entity.isAuthentic,
      confidence: entity.confidence,
      verdict: entity.verdict,
      summary: entity.summary,
      searchResults: entity.searchResults
          .map((result) => ImageSearchResultModel.fromEntity(result))
          .toList(),
      warnings: entity.warnings,
      metadata: entity.metadata,
    );
  }

  ImageAuthenticityEntity toEntity() {
    return ImageAuthenticityEntity(
      isAuthentic: isAuthentic,
      confidence: confidence,
      verdict: verdict,
      summary: summary,
      searchResults: searchResults.map((result) => result.copyWith()).toList(),
      warnings: warnings,
      metadata: metadata,
    );
  }
}

/// Model for image search result
class ImageSearchResultModel extends ImageSearchResultEntity {
  const ImageSearchResultModel({
    required super.apiSource,
    required super.totalMatches,
    required super.matches,
    required super.processingTime,
    required super.status,
  });

  factory ImageSearchResultModel.fromEntity(ImageSearchResultEntity entity) {
    return ImageSearchResultModel(
      apiSource: entity.apiSource,
      totalMatches: entity.totalMatches,
      matches: entity.matches
          .map((match) => ImageMatchModel.fromEntity(match))
          .toList(),
      processingTime: entity.processingTime,
      status: entity.status,
    );
  }

  ImageSearchResultEntity toEntity() {
    return ImageSearchResultEntity(
      apiSource: apiSource,
      totalMatches: totalMatches,
      matches: matches.map((match) => match.copyWith()).toList(),
      processingTime: processingTime,
      status: status,
    );
  }
}

/// Model for individual image match
class ImageMatchModel extends ImageMatchEntity {
  const ImageMatchModel({
    required super.sourceUrl,
    required super.thumbnailUrl,
    required super.hostPageUrl,
    required super.title,
    required super.description,
    required super.confidence,
    required super.dateFound,
    required super.width,
    required super.height,
  });

  factory ImageMatchModel.fromEntity(ImageMatchEntity entity) {
    return ImageMatchModel(
      sourceUrl: entity.sourceUrl,
      thumbnailUrl: entity.thumbnailUrl,
      hostPageUrl: entity.hostPageUrl,
      title: entity.title,
      description: entity.description,
      confidence: entity.confidence,
      dateFound: entity.dateFound,
      width: entity.width,
      height: entity.height,
    );
  }

  ImageMatchEntity toEntity() {
    return ImageMatchEntity(
      sourceUrl: sourceUrl,
      thumbnailUrl: thumbnailUrl,
      hostPageUrl: hostPageUrl,
      title: title,
      description: description,
      confidence: confidence,
      dateFound: dateFound,
      width: width,
      height: height,
    );
  }
}
