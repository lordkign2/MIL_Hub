import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_lesson_model.dart';
import '../models/user_progress_model.dart';
import 'learning_service.dart';
import 'offline_learning_service.dart';

/// Hybrid service that seamlessly works online and offline
class HybridLearningService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize both online and offline services
  static Future<void> initialize() async {
    await OfflineLearningService.initialize();
  }

  // Lessons with offline fallback
  static Stream<List<EnhancedLesson>> getLessonsStream({
    LessonDifficulty? difficulty,
    LessonType? type,
    List<String>? tags,
    bool? isFeatured,
    int limit = 20,
  }) async* {
    if (OfflineLearningService.isOnline) {
      // Online: Get from Firebase and cache
      await for (final lessons in LearningService.getLessonsStream(
        difficulty: difficulty,
        type: type,
        tags: tags,
        isFeatured: isFeatured,
        limit: limit,
      )) {
        // Cache lessons for offline use
        await OfflineLearningService.cacheLessons(lessons);
        yield lessons;
      }
    } else {
      // Offline: Get from cache
      final cachedLessons = await OfflineLearningService.getCachedLessons(
        limit: limit,
      );

      // Filter cached lessons based on criteria
      var filteredLessons = cachedLessons;

      if (difficulty != null) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.difficulty == difficulty)
            .toList();
      }

      if (type != null) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.type == type)
            .toList();
      }

      if (isFeatured != null) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.isFeatured == isFeatured)
            .toList();
      }

      if (tags != null && tags.isNotEmpty) {
        filteredLessons = filteredLessons
            .where((lesson) => lesson.tags.any((tag) => tags.contains(tag)))
            .toList();
      }

      yield filteredLessons.take(limit).toList();
    }
  }

  static Future<EnhancedLesson?> getLessonById(String lessonId) async {
    if (OfflineLearningService.isOnline) {
      // Try online first
      try {
        final lesson = await LearningService.getLessonById(lessonId);
        if (lesson != null) {
          // Cache for offline use
          await OfflineLearningService.cacheLesson(lesson);
          return lesson;
        }
      } catch (e) {
        // Fall back to offline if online fails
      }
    }

    // Get from cache
    return await OfflineLearningService.getCachedLesson(lessonId);
  }

  static Stream<List<EnhancedLesson>> getFeaturedLessons() async* {
    if (OfflineLearningService.isOnline) {
      await for (final lessons in LearningService.getFeaturedLessons()) {
        await OfflineLearningService.cacheLessons(lessons);
        yield lessons;
      }
    } else {
      final cachedLessons = await OfflineLearningService.getCachedLessons(
        limit: 5,
      );
      yield cachedLessons.where((lesson) => lesson.isFeatured).toList();
    }
  }

  static Stream<List<EnhancedLesson>> getRecommendedLessons() async* {
    if (OfflineLearningService.isOnline) {
      await for (final lessons in LearningService.getRecommendedLessons()) {
        await OfflineLearningService.cacheLessons(lessons);
        yield lessons;
      }
    } else {
      final cachedLessons = await OfflineLearningService.getCachedLessons(
        limit: 10,
      );
      yield cachedLessons;
    }
  }

  static Future<List<EnhancedLesson>> searchLessons(
    String query, {
    int limit = 20,
  }) async {
    if (OfflineLearningService.isOnline) {
      try {
        final lessons = await LearningService.searchLessons(
          query,
          limit: limit,
        );
        await OfflineLearningService.cacheLessons(lessons);
        return lessons;
      } catch (e) {
        // Fall back to offline search
      }
    }

    // Offline search
    final cachedLessons = await OfflineLearningService.getCachedLessons();
    return cachedLessons
        .where(
          (lesson) =>
              lesson.title.toLowerCase().contains(query.toLowerCase()) ||
              lesson.description.toLowerCase().contains(query.toLowerCase()) ||
              lesson.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .take(limit)
        .toList();
  }

  // User Progress with offline support
  static Stream<UserLessonProgress?> getUserLessonProgress(
    String lessonId,
  ) async* {
    final user = _auth.currentUser;
    if (user == null) return;

    if (OfflineLearningService.isOnline) {
      await for (final progress in LearningService.getUserLessonProgress(
        lessonId,
      )) {
        if (progress != null) {
          // Cache for offline access
          await OfflineLearningService.saveProgressOffline(
            user.uid,
            lessonId,
            progress,
          );
        }
        yield progress;
      }
    } else {
      // Get from offline storage
      final offlineProgress = await OfflineLearningService.getOfflineProgress(
        user.uid,
        lessonId,
      );
      yield offlineProgress;
    }
  }

  static Stream<List<UserLessonProgress>> getUserProgressStream() async* {
    final user = _auth.currentUser;
    if (user == null) return;

    if (OfflineLearningService.isOnline) {
      await for (final progressList
          in LearningService.getUserProgressStream()) {
        // Cache all progress for offline access
        for (final progress in progressList) {
          await OfflineLearningService.saveProgressOffline(
            user.uid,
            progress.lessonId,
            progress,
          );
        }
        yield progressList;
      }
    } else {
      // This would need to be implemented to get all offline progress
      // For now, return empty list
      yield <UserLessonProgress>[];
    }
  }

  static Future<void> updateLessonProgress({
    required String lessonId,
    required double progress,
    LessonStatus? status,
    int? additionalTimeSpent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (OfflineLearningService.isOnline) {
      try {
        // Update online
        await LearningService.updateLessonProgress(
          lessonId: lessonId,
          progress: progress,
          status: status,
          additionalTimeSpent: additionalTimeSpent,
        );
        return;
      } catch (e) {
        // If online update fails, save offline
      }
    }

    // Save offline for later sync
    final now = DateTime.now();
    final offlineProgress = UserLessonProgress(
      userId: user.uid,
      lessonId: lessonId,
      progress: progress,
      status: status ?? LessonStatus.inProgress,
      timeSpent: additionalTimeSpent ?? 0,
      lastAccessedAt: now,
      completedAt: status == LessonStatus.completed ? now : null,
    );

    await OfflineLearningService.saveProgressOffline(
      user.uid,
      lessonId,
      offlineProgress,
    );
  }

  static Future<void> toggleBookmark(String lessonId) async {
    if (OfflineLearningService.isOnline) {
      try {
        await LearningService.toggleBookmark(lessonId);
        return;
      } catch (e) {
        // Handle offline bookmark toggle
      }
    }

    // For offline bookmarking, we'd need to implement this
    // in the offline service as well
  }

  // Quiz Management with offline support
  static Future<String> submitQuizAttempt({
    required String lessonId,
    required List<QuestionAttempt> questionAttempts,
    required int timeSpent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final correctAnswers = questionAttempts.where((q) => q.isCorrect).length;
    final score = correctAnswers / questionAttempts.length;
    final now = DateTime.now();

    final quizAttempt = QuizAttempt(
      id: '${user.uid}_${lessonId}_${now.millisecondsSinceEpoch}',
      lessonId: lessonId,
      userId: user.uid,
      score: score,
      totalQuestions: questionAttempts.length,
      correctAnswers: correctAnswers,
      timeSpent: timeSpent,
      startedAt: now.subtract(Duration(seconds: timeSpent)),
      completedAt: now,
      questionAttempts: questionAttempts,
      analytics: {
        'averageTimePerQuestion': timeSpent / questionAttempts.length,
        'difficultyRating': _calculateDifficultyRating(questionAttempts),
      },
    );

    if (OfflineLearningService.isOnline) {
      try {
        // Submit online
        final onlineId = await LearningService.submitQuizAttempt(
          lessonId: lessonId,
          questionAttempts: questionAttempts,
          timeSpent: timeSpent,
        );
        return onlineId;
      } catch (e) {
        // If online submission fails, save offline
      }
    }

    // Save offline for later sync
    // Note: Quiz attempt offline saving would be implemented here

    // Also update progress offline
    await updateLessonProgress(
      lessonId: lessonId,
      progress: 1.0,
      status: score >= 0.7 ? LessonStatus.completed : LessonStatus.inProgress,
      additionalTimeSpent: timeSpent,
    );

    return quizAttempt.id;
  }

  static double _calculateDifficultyRating(List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    final totalTime = attempts.fold(
      0,
      (sum, attempt) => sum + attempt.timeSpent,
    );
    final averageTime = totalTime / attempts.length;
    final correctRate =
        attempts.where((a) => a.isCorrect).length / attempts.length;

    return (averageTime / 30.0) * (1.0 - correctRate) * 5.0;
  }

  // Offline Management Methods
  static Future<void> downloadLessonForOffline(String lessonId) async {
    await OfflineLearningService.downloadLessonForOffline(lessonId);
  }

  static Future<SyncResult> syncOfflineData() async {
    if (!OfflineLearningService.isOnline) {
      return SyncResult(success: false, error: 'No internet connection');
    }

    final progressResult = await OfflineLearningService.syncPendingProgress();
    final quizResult = await OfflineLearningService.syncPendingQuizAttempts();

    return SyncResult(
      success: progressResult.success && quizResult.success,
      successCount: progressResult.successCount + quizResult.successCount,
      failureCount: progressResult.failureCount + quizResult.failureCount,
    );
  }

  static OfflineStorageInfo getOfflineStorageInfo() {
    return OfflineLearningService.getStorageInfo();
  }

  static Future<void> clearOfflineCache() async {
    await OfflineLearningService.clearExpiredCache();
  }

  static Future<void> clearAllOfflineData() async {
    await OfflineLearningService.clearAllOfflineData();
  }

  // Connectivity status
  static bool get isOnline => OfflineLearningService.isOnline;
  static DateTime? get lastSyncTime => OfflineLearningService.lastSyncTime;

  // Analytics (offline-aware)
  static Future<void> recordLessonView(String lessonId) async {
    if (OfflineLearningService.isOnline) {
      try {
        await LearningService.recordLessonView(lessonId);
      } catch (e) {
        // Could implement offline analytics tracking
      }
    }
  }

  static Future<void> recordLessonRating(String lessonId, double rating) async {
    if (OfflineLearningService.isOnline) {
      try {
        await LearningService.recordLessonRating(lessonId, rating);
      } catch (e) {
        // Could implement offline rating storage
      }
    }
  }

  // User Statistics (hybrid)
  static Stream<UserLearningStats?> getUserStats() async* {
    if (OfflineLearningService.isOnline) {
      await for (final stats in LearningService.getUserStats()) {
        yield stats;
      }
    } else {
      // For offline, we'd need to calculate stats from cached data
      // This is a simplified implementation
      yield null;
    }
  }

  // Achievement and progress methods delegate to LearningService when online
  static Stream<List<Achievement>> getUserAchievements() {
    if (OfflineLearningService.isOnline) {
      return LearningService.getUserAchievements();
    } else {
      return Stream.value(<Achievement>[]);
    }
  }

  static Future<List<Achievement>> getAllPossibleAchievements() {
    if (OfflineLearningService.isOnline) {
      return LearningService.getAllPossibleAchievements();
    } else {
      return Future.value(<Achievement>[]);
    }
  }

  static Future<Map<String, dynamic>> getDetailedProgress() {
    if (OfflineLearningService.isOnline) {
      return LearningService.getDetailedProgress();
    } else {
      return Future.value(<String, dynamic>{});
    }
  }

  static Stream<List<UserLessonProgress>> getBookmarkedLessons() {
    if (OfflineLearningService.isOnline) {
      return LearningService.getBookmarkedLessons();
    } else {
      return Stream.value(<UserLessonProgress>[]);
    }
  }
}
