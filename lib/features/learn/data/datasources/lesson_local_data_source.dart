import '../models/lesson_model.dart';
import '../providers/lesson_data_provider.dart';
import '../../../../core/errors/exceptions.dart';

/// Abstract interface for local lesson data source
abstract class LessonLocalDataSource {
  /// Get all lessons from local storage
  Future<List<LessonModel>> getAllLessons();

  /// Get a lesson by ID from local storage
  Future<LessonModel> getLessonById(String id);

  /// Cache lessons locally
  Future<void> cacheLessons(List<LessonModel> lessons);

  /// Get user progress from local storage
  Future<Map<String, int>> getUserProgress();

  /// Save user progress to local storage
  Future<void> saveUserProgress(String lessonId, int progress);

  /// Clear cached lessons
  Future<void> clearCachedLessons();

  /// Clear user progress
  Future<void> clearUserProgress();
}

/// Mock implementation of LessonLocalDataSource
class MockLessonLocalDataSource implements LessonLocalDataSource {
  final List<LessonModel> _cachedLessons = [];
  final Map<String, int> _userProgress = {};

  @override
  Future<List<LessonModel>> getAllLessons() async {
    // If no cached lessons, populate with initial data
    if (_cachedLessons.isEmpty) {
      final lessons = LessonDataProvider.getAllLessons();
      _cachedLessons.addAll(
        lessons.map((entity) => LessonModel.fromEntity(entity)).toList(),
      );
    }

    return List<LessonModel>.from(_cachedLessons);
  }

  @override
  Future<LessonModel> getLessonById(String id) async {
    try {
      // First check cache
      if (_cachedLessons.isNotEmpty) {
        final lesson = _cachedLessons.firstWhere((lesson) => lesson.id == id);
        return lesson;
      }

      // If cache is empty, get from provider
      final entity = LessonDataProvider.getLessonById(id);
      if (entity != null) {
        final model = LessonModel.fromEntity(entity);
        _cachedLessons.add(model);
        return model;
      }

      throw const CacheException(message: 'Lesson not found');
    } catch (e) {
      throw const CacheException(message: 'Lesson not found in cache');
    }
  }

  @override
  Future<void> cacheLessons(List<LessonModel> lessons) async {
    _cachedLessons.clear();
    _cachedLessons.addAll(lessons);
  }

  @override
  Future<Map<String, int>> getUserProgress() async {
    return Map<String, int>.from(_userProgress);
  }

  @override
  Future<void> saveUserProgress(String lessonId, int progress) async {
    _userProgress[lessonId] = progress;
  }

  @override
  Future<void> clearCachedLessons() async {
    _cachedLessons.clear();
  }

  @override
  Future<void> clearUserProgress() async {
    _userProgress.clear();
  }
}
