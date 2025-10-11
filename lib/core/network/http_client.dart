import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// Abstract interface for HTTP client operations
abstract class HttpClient {
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  });
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  });
  void setAuthToken(String token);
  void clearAuthToken();
}

/// Dio implementation of HttpClient
class DioHttpClient implements HttpClient {
  late final Dio _dio;

  DioHttpClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleDioError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(message: 'Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          throw AuthException(message: 'Unauthorized access');
        } else if (statusCode == 403) {
          throw AuthException(message: 'Access forbidden');
        } else if (statusCode == 404) {
          throw ServerException(message: 'Resource not found');
        } else if (statusCode != null && statusCode >= 500) {
          throw ServerException(message: 'Server error occurred');
        } else {
          throw ServerException(
            message: 'Request failed with status: $statusCode',
          );
        }
      case DioExceptionType.cancel:
        throw NetworkException(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        throw NetworkException(message: 'No internet connection');
      case DioExceptionType.unknown:
        throw NetworkException(message: 'Unknown network error occurred');
      default:
        throw NetworkException(message: 'Network error occurred');
    }
  }

  @override
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  @override
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
