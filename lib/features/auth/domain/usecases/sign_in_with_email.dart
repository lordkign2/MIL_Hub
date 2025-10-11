import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with email and password
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  Future<({UserEntity? user, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    // Basic validation
    if (email.trim().isEmpty) {
      return (
        user: null,
        failure: const ValidationFailure('Email is required'),
      );
    }

    if (password.trim().isEmpty) {
      return (
        user: null,
        failure: const ValidationFailure('Password is required'),
      );
    }

    return await _repository.signInWithEmail(email: email, password: password);
  }
}
