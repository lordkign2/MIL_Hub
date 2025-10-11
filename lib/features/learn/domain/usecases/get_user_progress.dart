import '../../../../core/errors/failures.dart';
import '../repositories/lesson_repository.dart';

/// Use case for getting user progress
class GetUserProgressUseCase {
  final LessonRepository _repository;

  GetUserProgressUseCase(this._repository);

  Future<({Map<String, int>? progress, Failure? failure})> call() async {
    return await _repository.getUserProgress();
  }
}
