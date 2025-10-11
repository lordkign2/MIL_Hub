import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';

/// Abstract repository interface for lesson operations
abstract class LessonRepository {
  /// Get all lessons
  Future<({List<LessonEntity>? lessons, Failure? failure})> getAllLessons();

  /// Get a lesson by ID
  Future<({LessonEntity? lesson, Failure? failure})> getLessonById(String id);

  /// Get lessons by category or filter
  Future<({List<LessonEntity>? lessons, Failure? failure})> getLessonsByFilter({
    String? category,
    int? limit,
    String? searchQuery,
  });

  /// Update lesson progress
  Future<({bool success, Failure? failure})> updateLessonProgress({
    required String lessonId,
    required int progress,
  });

  /// Get user progress for all lessons
  Future<({Map<String, int>? progress, Failure? failure})> getUserProgress();

  /// Save user progress
  Future<({bool success, Failure? failure})> saveUserProgress({
    required String lessonId,
    required int progress,
  });

  /// Complete a lesson
  Future<({bool success, Failure? failure})> completeLesson(String lessonId);

  /// Get completed lessons count
  Future<({int? count, Failure? failure})> getCompletedLessonsCount();
}
