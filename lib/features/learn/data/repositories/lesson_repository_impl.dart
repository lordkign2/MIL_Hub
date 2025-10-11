import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_local_data_source.dart';
import '../datasources/lesson_remote_data_source.dart';
import '../models/lesson_model.dart';

/// Implementation of LessonRepository
class LessonRepositoryImpl implements LessonRepository {
  final LessonRemoteDataSource _remoteDataSource;
  final LessonLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  LessonRepositoryImpl({
    required LessonRemoteDataSource remoteDataSource,
    required LessonLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  @override
  Future<({List<LessonEntity>? lessons, Failure? failure})>
  getAllLessons() async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteLessons = await _remoteDataSource.getAllLessons();

        // Cache the lessons locally
        await _localDataSource.cacheLessons(remoteLessons);

        return (
          lessons: remoteLessons.map((model) => model.toEntity()).toList(),
          failure: null,
        );
      } on ServerException catch (e) {
        return (lessons: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (lessons: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          lessons: null,
          failure: UnknownFailure(message: 'Failed to get lessons: $e'),
        );
      }
    } else {
      // Try to get from local cache when offline
      try {
        final localLessons = await _localDataSource.getAllLessons();
        return (
          lessons: localLessons.map((model) => model.toEntity()).toList(),
          failure: null,
        );
      } on CacheException catch (e) {
        return (lessons: null, failure: CacheFailure(message: e.message));
      } catch (e) {
        return (
          lessons: null,
          failure: UnknownFailure(message: 'Failed to get cached lessons: $e'),
        );
      }
    }
  }

  @override
  Future<({LessonEntity? lesson, Failure? failure})> getLessonById(
    String id,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteLesson = await _remoteDataSource.getLessonById(id);
        return (lesson: remoteLesson.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (lesson: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        // Try local cache as fallback
        try {
          final localLesson = await _localDataSource.getLessonById(id);
          return (lesson: localLesson.toEntity(), failure: null);
        } on CacheException catch (e) {
          return (lesson: null, failure: CacheFailure(message: e.message));
        }
      } catch (e) {
        return (
          lesson: null,
          failure: UnknownFailure(message: 'Failed to get lesson: $e'),
        );
      }
    } else {
      // Try to get from local cache when offline
      try {
        final localLesson = await _localDataSource.getLessonById(id);
        return (lesson: localLesson.toEntity(), failure: null);
      } on CacheException catch (e) {
        return (lesson: null, failure: CacheFailure(message: e.message));
      } catch (e) {
        return (
          lesson: null,
          failure: UnknownFailure(message: 'Failed to get cached lesson: $e'),
        );
      }
    }
  }

  @override
  Future<({List<LessonEntity>? lessons, Failure? failure})> getLessonsByFilter({
    String? category,
    int? limit,
    String? searchQuery,
  }) async {
    // For now, we'll get all lessons and filter locally
    // In a real implementation, this would be done on the server side
    final result = await getAllLessons();

    if (result.lessons != null) {
      List<LessonEntity> filteredLessons = result.lessons!;

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredLessons = filteredLessons.where((lesson) {
          return lesson.title.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              lesson.subtitle.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              lesson.content.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      // Apply limit if provided
      if (limit != null && limit > 0 && filteredLessons.length > limit) {
        filteredLessons = filteredLessons.take(limit).toList();
      }

      return (lessons: filteredLessons, failure: null);
    }

    return (lessons: null, failure: result.failure);
  }

  @override
  Future<({bool success, Failure? failure})> updateLessonProgress({
    required String lessonId,
    required int progress,
  }) async {
    // In a real implementation, we would get the current user ID
    // For now, we'll use a mock user ID
    const userId = 'mock_user_id';

    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.saveUserProgress(userId, lessonId, progress);
        await _localDataSource.saveUserProgress(lessonId, progress);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to update progress: $e'),
        );
      }
    } else {
      // Save locally when offline
      try {
        await _localDataSource.saveUserProgress(lessonId, progress);
        return (
          success: true,
          failure: const NetworkFailure(
            message: 'Progress saved locally. Will sync when online.',
          ),
        );
      } on CacheException catch (e) {
        return (success: false, failure: CacheFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(
            message: 'Failed to save progress locally: $e',
          ),
        );
      }
    }
  }

  @override
  Future<({Map<String, int>? progress, Failure? failure})>
  getUserProgress() async {
    // In a real implementation, we would get the current user ID
    // For now, we'll use a mock user ID
    const userId = 'mock_user_id';

    if (await _networkInfo.isConnected) {
      try {
        final remoteProgress = await _remoteDataSource.getUserProgress(userId);

        // Also update local cache
        for (final entry in remoteProgress.entries) {
          await _localDataSource.saveUserProgress(entry.key, entry.value);
        }

        return (progress: remoteProgress, failure: null);
      } on ServerException catch (e) {
        return (progress: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        // Try local cache as fallback
        try {
          final localProgress = await _localDataSource.getUserProgress();
          return (
            progress: localProgress,
            failure: const NetworkFailure(
              message: 'Showing cached progress. Last synced when online.',
            ),
          );
        } on CacheException catch (e) {
          return (progress: null, failure: CacheFailure(message: e.message));
        }
      } catch (e) {
        return (
          progress: null,
          failure: UnknownFailure(message: 'Failed to get user progress: $e'),
        );
      }
    } else {
      // Try to get from local cache when offline
      try {
        final localProgress = await _localDataSource.getUserProgress();
        return (
          progress: localProgress,
          failure: const NetworkFailure(
            message: 'Showing cached progress. Last synced when online.',
          ),
        );
      } on CacheException catch (e) {
        return (progress: null, failure: CacheFailure(message: e.message));
      } catch (e) {
        return (
          progress: null,
          failure: UnknownFailure(message: 'Failed to get cached progress: $e'),
        );
      }
    }
  }

  @override
  Future<({bool success, Failure? failure})> saveUserProgress({
    required String lessonId,
    required int progress,
  }) async {
    return await updateLessonProgress(lessonId: lessonId, progress: progress);
  }

  @override
  Future<({bool success, Failure? failure})> completeLesson(
    String lessonId,
  ) async {
    // In a real implementation, we would get the current user ID
    // For now, we'll use a mock user ID
    const userId = 'mock_user_id';

    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.completeLesson(userId, lessonId);
        await _localDataSource.saveUserProgress(lessonId, 100);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to complete lesson: $e'),
        );
      }
    } else {
      // Save locally when offline
      try {
        await _localDataSource.saveUserProgress(lessonId, 100);
        return (
          success: true,
          failure: const NetworkFailure(
            message:
                'Lesson marked as complete locally. Will sync when online.',
          ),
        );
      } on CacheException catch (e) {
        return (success: false, failure: CacheFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(
            message: 'Failed to mark lesson complete locally: $e',
          ),
        );
      }
    }
  }

  @override
  Future<({int? count, Failure? failure})> getCompletedLessonsCount() async {
    final result = await getUserProgress();

    if (result.progress != null) {
      final completedCount = result.progress!.values
          .where((progress) => progress >= 100)
          .length;
      return (count: completedCount, failure: null);
    }

    return (count: null, failure: result.failure);
  }
}
