import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/lesson_repository.dart';

/// Use case for getting a lesson by ID
class GetLessonByIdUseCase {
  final LessonRepository _repository;

  GetLessonByIdUseCase(this._repository);

  Future<({LessonEntity? lesson, Failure? failure})> call(String id) async {
    if (id.isEmpty) {
      return (
        lesson: null,
        failure: const ValidationFailure(message: 'Lesson ID cannot be empty'),
      );
    }

    return await _repository.getLessonById(id);
  }
}
