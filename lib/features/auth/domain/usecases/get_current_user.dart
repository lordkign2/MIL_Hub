import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting current user
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  UserEntity? call() {
    return _repository.getCurrentUser();
  }
}
