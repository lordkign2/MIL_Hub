import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'verification_models.dart';

class VerificationApiService {
  static const String _baseUrl = 'http://localhost:8080/api';
  static const Duration _timeout = Duration(seconds: 30);

  late final Dio _dio;

  VerificationApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('API Request: ${options.method} ${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('API Response: ${response.statusCode} ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('API Error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Upload media file for verification
  Future<MediaUploadResponse> uploadMedia({
    required File file,
    required String userId,
    String? metadata,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
        'user_id': userId,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await _dio.post('/upload', data: formData);
      return MediaUploadResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Upload failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Start verification process
  Future<VerificationResponse> startVerification({
    required String mediaId,
    required String token,
    List<String> verificationTypes = const ['image', 'context'],
    String priority = 'normal',
  }) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post(
        '/analyze',
        data: {
          'media_id': mediaId,
          'verification_types': verificationTypes,
          'priority': priority,
        },
      );

      return VerificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Verification start failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Get verification result
  Future<VerificationResult> getVerificationResult({
    required String jobId,
    required String token,
  }) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/results/$jobId');
      return VerificationResult.fromJson(response.data);
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Result retrieval failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Get media processing status
  Future<MediaStatusResponse> getMediaStatus(String mediaId) async {
    try {
      final response = await _dio.get('/media/$mediaId/status');
      return MediaStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Status check failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Delete media file
  Future<void> deleteMedia({
    required String mediaId,
    required String token,
  }) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.delete('/media/$mediaId');
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Delete failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload with progress tracking
  Future<MediaUploadResponse> uploadMediaWithProgress({
    required File file,
    required String userId,
    String? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
        'user_id': userId,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      return MediaUploadResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw VerificationApiException(
        message: 'Upload failed: ${e.message}',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  /// Poll for verification results
  Future<VerificationResult> pollForResult({
    required String jobId,
    required String token,
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      try {
        final result = await getVerificationResult(jobId: jobId, token: token);
        if (result.status == 'completed' || result.status == 'failed') {
          return result;
        }

        await Future.delayed(pollInterval);
      } catch (e) {
        // Continue polling on error
        await Future.delayed(pollInterval);
      }
    }

    throw VerificationApiException(
      message: 'Verification timeout after ${timeout.inMinutes} minutes',
      statusCode: 408,
    );
  }
}

class VerificationApiException implements Exception {
  final String message;
  final int statusCode;

  VerificationApiException({required this.message, required this.statusCode});

  @override
  String toString() =>
      'VerificationApiException: $message (Status: $statusCode)';
}
