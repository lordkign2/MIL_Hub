import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting auth state changes stream
class GetAuthStateStreamUseCase {
  final AuthRepository _repository;

  GetAuthStateStreamUseCase(this._repository);

  Stream<UserEntity?> call() {
    return _repository.authStateChanges;
  }
}
