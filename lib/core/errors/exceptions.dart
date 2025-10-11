/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppException(message: $message, code: $code)';
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noInternet() {
    return const NetworkException(
      message: 'No internet connection',
      code: 'NO_INTERNET',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(message: 'Request timeout', code: 'TIMEOUT');
  }

  factory NetworkException.badRequest() {
    return const NetworkException(message: 'Bad request', code: 'BAD_REQUEST');
  }

  factory NetworkException.unauthorized() {
    return const NetworkException(
      message: 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }

  factory NetworkException.forbidden() {
    return const NetworkException(
      message: 'Access forbidden',
      code: 'FORBIDDEN',
    );
  }

  factory NetworkException.notFound() {
    return const NetworkException(
      message: 'Resource not found',
      code: 'NOT_FOUND',
    );
  }

  factory NetworkException.serverError() {
    return const NetworkException(
      message: 'Internal server error',
      code: 'SERVER_ERROR',
    );
  }
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() {
    return const AuthException(
      message: 'Invalid credentials provided',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthException.userNotFound() {
    return const AuthException(
      message: 'User not found',
      code: 'USER_NOT_FOUND',
    );
  }

  factory AuthException.emailAlreadyInUse() {
    return const AuthException(
      message: 'Email already in use',
      code: 'EMAIL_ALREADY_IN_USE',
    );
  }

  factory AuthException.weakPassword() {
    return const AuthException(
      message: 'Password is too weak',
      code: 'WEAK_PASSWORD',
    );
  }

  factory AuthException.tokenExpired() {
    return const AuthException(
      message: 'Token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CacheException.notFound() {
    return const CacheException(
      message: 'Data not found in cache',
      code: 'CACHE_NOT_FOUND',
    );
  }

  factory CacheException.writeError() {
    return const CacheException(
      message: 'Failed to write to cache',
      code: 'CACHE_WRITE_ERROR',
    );
  }

  factory CacheException.readError() {
    return const CacheException(
      message: 'Failed to read from cache',
      code: 'CACHE_READ_ERROR',
    );
  }
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseException.connectionFailed() {
    return const DatabaseException(
      message: 'Database connection failed',
      code: 'CONNECTION_FAILED',
    );
  }

  factory DatabaseException.queryFailed() {
    return const DatabaseException(
      message: 'Database query failed',
      code: 'QUERY_FAILED',
    );
  }

  factory DatabaseException.dataNotFound() {
    return const DatabaseException(
      message: 'Requested data not found',
      code: 'DATA_NOT_FOUND',
    );
  }
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidInput(String field) {
    return ValidationException(
      message: 'Invalid input for $field',
      code: 'INVALID_INPUT',
    );
  }

  factory ValidationException.requiredField(String field) {
    return ValidationException(
      message: '$field is required',
      code: 'REQUIRED_FIELD',
    );
  }
}

/// File operation exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory FileException.notFound() {
    return const FileException(
      message: 'File not found',
      code: 'FILE_NOT_FOUND',
    );
  }

  factory FileException.accessDenied() {
    return const FileException(
      message: 'File access denied',
      code: 'ACCESS_DENIED',
    );
  }

  factory FileException.invalidFormat() {
    return const FileException(
      message: 'Invalid file format',
      code: 'INVALID_FORMAT',
    );
  }

  factory FileException.tooLarge() {
    return const FileException(
      message: 'File size too large',
      code: 'FILE_TOO_LARGE',
    );
  }
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PermissionException.denied() {
    return const PermissionException(
      message: 'Permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory PermissionException.insufficientPrivileges() {
    return const PermissionException(
      message: 'Insufficient privileges',
      code: 'INSUFFICIENT_PRIVILEGES',
    );
  }
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ServerException.internal() {
    return const ServerException(
      message: 'Internal server error',
      code: 'INTERNAL_SERVER_ERROR',
    );
  }

  factory ServerException.maintenance() {
    return const ServerException(
      message: 'Server is under maintenance',
      code: 'MAINTENANCE',
    );
  }

  factory ServerException.badGateway() {
    return const ServerException(message: 'Bad gateway', code: 'BAD_GATEWAY');
  }
}
