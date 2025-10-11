import '../models/lesson_model.dart';
import '../providers/lesson_data_provider.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/lesson_local_data_source.dart';

/// Abstract interface for remote lesson data source
abstract class LessonRemoteDataSource {
  /// Get all lessons from remote source
  Future<List<LessonModel>> getAllLessons();

  /// Get a lesson by ID from remote source
  Future<LessonModel> getLessonById(String id);

  /// Get user progress from remote source
  Future<Map<String, int>> getUserProgress(String userId);

  /// Save user progress to remote source
  Future<void> saveUserProgress(String userId, String lessonId, int progress);

  /// Complete a lesson for user
  Future<void> completeLesson(String userId, String lessonId);
}

/// Mock implementation of LessonRemoteDataSource
class MockLessonRemoteDataSource implements LessonRemoteDataSource {
  final LessonLocalDataSource _localDataSource;

  MockLessonRemoteDataSource({required LessonLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<List<LessonModel>> getAllLessons() async {
    // In a real implementation, this would fetch from a remote API or database
    // For now, we'll return the cached lessons from local storage
    try {
      return await _localDataSource.getAllLessons();
    } catch (e) {
      // If no cached lessons, get from provider
      final lessons = LessonDataProvider.getAllLessons();
      final models = lessons
          .map((entity) => LessonModel.fromEntity(entity))
          .toList();

      // Cache the lessons
      await _localDataSource.cacheLessons(models);

      return models;
    }
  }

  @override
  Future<LessonModel> getLessonById(String id) async {
    // In a real implementation, this would fetch from a remote API or database
    try {
      return await _localDataSource.getLessonById(id);
    } catch (e) {
      // If not in cache, get from provider
      final entity = LessonDataProvider.getLessonById(id);
      if (entity != null) {
        final model = LessonModel.fromEntity(entity);

        // Cache the lesson
        final cachedLessons = await _localDataSource.getAllLessons();
        cachedLessons.add(model);
        await _localDataSource.cacheLessons(cachedLessons);

        return model;
      }

      throw const ServerException(message: 'Lesson not found');
    }
  }

  @override
  Future<Map<String, int>> getUserProgress(String userId) async {
    // In a real implementation, this would fetch from a remote API or database
    try {
      return await _localDataSource.getUserProgress();
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> saveUserProgress(
    String userId,
    String lessonId,
    int progress,
  ) async {
    // In a real implementation, this would save to a remote API or database
    try {
      await _localDataSource.saveUserProgress(lessonId, progress);
    } catch (e) {
      throw const ServerException(message: 'Failed to save progress');
    }
  }

  @override
  Future<void> completeLesson(String userId, String lessonId) async {
    // In a real implementation, this would save to a remote API or database
    try {
      await _localDataSource.saveUserProgress(lessonId, 100);
    } catch (e) {
      throw const ServerException(message: 'Failed to complete lesson');
    }
  }
}
