/// Base class for all application failures
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({required this.message, this.code, this.originalError});

  @override
  String toString() {
    return 'Failure(message: $message, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory NetworkFailure.noInternet() {
    return const NetworkFailure(
      message: 'No internet connection available',
      code: 'NO_INTERNET',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(message: 'Connection timeout', code: 'TIMEOUT');
  }

  factory NetworkFailure.serverError([String? message]) {
    return NetworkFailure(
      message: message ?? 'Server error occurred',
      code: 'SERVER_ERROR',
    );
  }
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.originalError});

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Invalid email or password',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthFailure.userNotFound() {
    return const AuthFailure(
      message: 'No user found with this email',
      code: 'USER_NOT_FOUND',
    );
  }

  factory AuthFailure.emailAlreadyInUse() {
    return const AuthFailure(
      message: 'An account already exists with this email',
      code: 'EMAIL_ALREADY_IN_USE',
    );
  }

  factory AuthFailure.weakPassword() {
    return const AuthFailure(
      message: 'Password is too weak',
      code: 'WEAK_PASSWORD',
    );
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Authentication token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }

  factory AuthFailure.unauthorized() {
    return const AuthFailure(
      message: 'You are not authorized to perform this action',
      code: 'UNAUTHORIZED',
    );
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.originalError});

  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Requested data not found in cache',
      code: 'CACHE_NOT_FOUND',
    );
  }

  factory CacheFailure.writeError() {
    return const CacheFailure(
      message: 'Failed to write data to cache',
      code: 'CACHE_WRITE_ERROR',
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory ValidationFailure.invalidEmail() {
    return const ValidationFailure(
      message: 'Please enter a valid email address',
      code: 'INVALID_EMAIL',
    );
  }

  factory ValidationFailure.invalidPassword() {
    return const ValidationFailure(
      message: 'Password must be at least 8 characters long',
      code: 'INVALID_PASSWORD',
    );
  }

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName cannot be empty',
      code: 'EMPTY_FIELD',
    );
  }
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory PermissionFailure.denied() {
    return const PermissionFailure(
      message: 'Permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory PermissionFailure.adminRequired() {
    return const PermissionFailure(
      message: 'Administrator privileges required',
      code: 'ADMIN_REQUIRED',
    );
  }
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure({required super.message, super.code, super.originalError});

  factory FileFailure.notFound() {
    return const FileFailure(message: 'File not found', code: 'FILE_NOT_FOUND');
  }

  factory FileFailure.tooLarge() {
    return const FileFailure(
      message: 'File size exceeds the maximum limit',
      code: 'FILE_TOO_LARGE',
    );
  }

  factory FileFailure.invalidFormat() {
    return const FileFailure(
      message: 'Invalid file format',
      code: 'INVALID_FORMAT',
    );
  }
}

/// Generic server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory ServerFailure.internal() {
    return const ServerFailure(
      message: 'Internal server error occurred',
      code: 'INTERNAL_SERVER_ERROR',
    );
  }

  factory ServerFailure.maintenance() {
    return const ServerFailure(
      message: 'Server is under maintenance',
      code: 'MAINTENANCE',
    );
  }
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory UnknownFailure.unexpected([String? message]) {
    return UnknownFailure(
      message: message ?? 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }
}
