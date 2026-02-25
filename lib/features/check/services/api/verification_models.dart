import 'dart:convert';

class MediaUploadResponse {
  final String mediaId;
  final String mediaType;
  final String fileName;
  final int fileSize;
  final DateTime uploadTimestamp;
  final String status;

  MediaUploadResponse({
    required this.mediaId,
    required this.mediaType,
    required this.fileName,
    required this.fileSize,
    required this.uploadTimestamp,
    required this.status,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      mediaId: json['media_id'] ?? json['mediaId'] ?? '',
      mediaType: json['media_type'] ?? json['mediaType'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      uploadTimestamp: DateTime.parse(
        json['upload_timestamp'] ??
            json['uploadTimestamp'] ??
            DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'media_type': mediaType,
      'file_name': fileName,
      'file_size': fileSize,
      'upload_timestamp': uploadTimestamp.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class VerificationResponse {
  final String jobId;
  final String mediaId;
  final String status;
  final DateTime createdAt;
  final DateTime? estimatedCompletion;

  VerificationResponse({
    required this.jobId,
    required this.mediaId,
    required this.status,
    required this.createdAt,
    this.estimatedCompletion,
  });

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      jobId: json['job_id'] ?? json['jobId'] ?? '',
      mediaId: json['media_id'] ?? json['mediaId'] ?? '',
      status: json['status'] ?? 'unknown',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'media_id': mediaId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (estimatedCompletion != null)
        'estimated_completion': estimatedCompletion!.toIso8601String(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class VerificationResult {
  final String jobId;
  final String mediaId;
  final double trustScore;
  final String verdict;
  final Map<String, dynamic> detailedResults;
  final List<String> recommendations;
  final DateTime createdAt;
  final String status;

  VerificationResult({
    required this.jobId,
    required this.mediaId,
    required this.trustScore,
    required this.verdict,
    required this.detailedResults,
    required this.recommendations,
    required this.createdAt,
    this.status = 'completed',
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      jobId: json['job_id'] ?? json['jobId'] ?? '',
      mediaId: json['media_id'] ?? json['mediaId'] ?? '',
      trustScore: (json['trust_score'] ?? json['trustScore'] ?? 0.0).toDouble(),
      verdict: json['verdict'] ?? 'unknown',
      detailedResults: json['detailed_results'] is String
          ? jsonDecode(json['detailed_results'])
          : json['detailed_results'] ?? {},
      recommendations: List<String>.from(
        json['recommendations'] ?? json['recommendations'] ?? [],
      ),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'media_id': mediaId,
      'trust_score': trustScore,
      'verdict': verdict,
      'detailed_results': detailedResults,
      'recommendations': recommendations,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class MediaStatusResponse {
  final String mediaId;
  final String status;
  final double? progress;
  final DateTime? estimatedCompletion;
  final String? errorMessage;

  MediaStatusResponse({
    required this.mediaId,
    required this.status,
    this.progress,
    this.estimatedCompletion,
    this.errorMessage,
  });

  factory MediaStatusResponse.fromJson(Map<String, dynamic> json) {
    return MediaStatusResponse(
      mediaId: json['media_id'] ?? json['mediaId'] ?? '',
      status: json['status'] ?? 'unknown',
      progress: (json['progress'] ?? 0.0).toDouble(),
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'])
          : null,
      errorMessage: json['error_message'] ?? json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'status': status,
      if (progress != null) 'progress': progress,
      if (estimatedCompletion != null)
        'estimated_completion': estimatedCompletion!.toIso8601String(),
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

// Extension methods for backward compatibility
extension VerificationResponseExtension on VerificationResponse {
  // For compatibility with existing code that might expect different field names
  String get id => jobId;
  DateTime get timestamp => createdAt;
}
