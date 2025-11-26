import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up with email and password
class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  SignUpWithEmailUseCase(this._repository);

  Future<({UserEntity? user, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      return (
        user: null,
        failure: const ValidationFailure(message: 'Invalid email format'),
      );
    }

    // Validate password strength
    if (!_isValidPassword(password)) {
      return (
        user: null,
        failure: const ValidationFailure(
          message: 'Password must be at least 8 characters long',
        ),
      );
    }

    return await _repository.signUpWithEmail(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }
}
