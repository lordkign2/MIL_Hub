import '../../../../core/errors/failures.dart';
import '../repositories/lesson_repository.dart';

/// Use case for updating lesson progress
class UpdateLessonProgressUseCase {
  final LessonRepository _repository;

  UpdateLessonProgressUseCase(this._repository);

  Future<({bool success, Failure? failure})> call({
    required String lessonId,
    required int progress,
  }) async {
    if (lessonId.isEmpty) {
      return (
        success: false,
        failure: const ValidationFailure(message: 'Lesson ID cannot be empty'),
      );
    }

    if (progress < 0 || progress > 100) {
      return (
        success: false,
        failure: const ValidationFailure(
          message: 'Progress must be between 0 and 100',
        ),
      );
    }

    return await _repository.updateLessonProgress(
      lessonId: lessonId,
      progress: progress,
    );
  }
}
