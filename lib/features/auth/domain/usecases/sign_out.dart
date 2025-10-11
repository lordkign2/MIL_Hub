import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing out
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<({bool success, Failure? failure})> call() async {
    return await _repository.signOut();
  }
}
