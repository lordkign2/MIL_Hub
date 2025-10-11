import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/lesson_repository.dart';

/// Use case for getting all lessons
class GetAllLessonsUseCase {
  final LessonRepository _repository;

  GetAllLessonsUseCase(this._repository);

  Future<({List<LessonEntity>? lessons, Failure? failure})> call() async {
    return await _repository.getAllLessons();
  }
}
