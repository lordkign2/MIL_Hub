// Simplified Offline Learning Service
// NOTE: This is a conceptual implementation that demonstrates the architecture
// In production, you would add packages like:
// - hive_flutter: for local storage
// - connectivity_plus: for network connectivity monitoring
// - dio: for advanced HTTP requests and file downloads

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/enhanced_lesson_model.dart';
import '../models/user_progress_model.dart';

// Simplified storage models (would use Hive annotations in production)
class OfflineLessonCache {
  final String lessonId;
  final String lessonData;
  final DateTime cachedAt;
  final bool isDownloaded;

  OfflineLessonCache({
    required this.lessonId,
    required this.lessonData,
    required this.cachedAt,
    this.isDownloaded = false,
  });
}

class OfflineProgressSync {
  final String id;
  final String userId;
  final String lessonId;
  final String progressData;
  final DateTime modifiedAt;
  final SyncStatus status;

  OfflineProgressSync({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.progressData,
    required this.modifiedAt,
    this.status = SyncStatus.pending,
  });
}

enum SyncStatus { pending, syncing, synced, failed }

// Simplified Offline Service
class OfflineLearningService {
  static final Map<String, OfflineLessonCache> _lessonCache = {};
  static final Map<String, OfflineProgressSync> _progressCache = {};
  static bool _isOnline = true;
  static DateTime? _lastSyncTime;

  static Future<void> initialize() async {
    // In production, initialize Hive and connectivity monitoring
    print('Offline Learning Service initialized (simplified version)');
  }

  // Simplified connectivity management
  static bool get isOnline => _isOnline;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static void setOnlineStatus(bool online) {
    _isOnline = online;
  }

  // Lesson caching
  static Future<void> cacheLesson(EnhancedLesson lesson) async {
    final cache = OfflineLessonCache(
      lessonId: lesson.id,
      lessonData: jsonEncode({
        'id': lesson.id,
        'title': lesson.title,
        'subtitle': lesson.subtitle,
        'description': lesson.description,
        'content': lesson.content,
        'difficulty': lesson.difficulty.toString(),
        'estimatedDuration': lesson.estimatedDuration,
        'themeColor': lesson.themeColor.value,
        'iconName': lesson.iconName,
        'tags': lesson.tags,
        'isFeatured': lesson.isFeatured,
        'createdAt': lesson.createdAt.millisecondsSinceEpoch,
      }),
      cachedAt: DateTime.now(),
    );
    _lessonCache[lesson.id] = cache;
  }

  static Future<void> cacheLessons(List<EnhancedLesson> lessons) async {
    for (final lesson in lessons) {
      await cacheLesson(lesson);
    }
  }

  static Future<EnhancedLesson?> getCachedLesson(String lessonId) async {
    final cache = _lessonCache[lessonId];
    if (cache == null) return null;

    try {
      final lessonMap = jsonDecode(cache.lessonData);
      return EnhancedLesson(
        id: lessonMap['id'],
        title: lessonMap['title'],
        subtitle: lessonMap['subtitle'],
        description: lessonMap['description'],
        content: lessonMap['content'],
        difficulty: LessonDifficulty.values.firstWhere(
          (d) => d.toString() == lessonMap['difficulty'],
          orElse: () => LessonDifficulty.beginner,
        ),
        estimatedDuration: lessonMap['estimatedDuration'],
        themeColor: Color(lessonMap['themeColor']),
        iconName: lessonMap['iconName'],
        tags: List<String>.from(lessonMap['tags'] ?? []),
        isFeatured: lessonMap['isFeatured'] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(lessonMap['createdAt']),
        order: 1,
        analytics: LessonAnalytics(
          viewCount: 0,
          completionRate: 0.0,
          averageRating: 0.0,
          averageTimeSpent: 0,
          ratingCount: 0,
        ),
        learningObjectives: [],
        prerequisites: [],
        resources: [],
        questions: [],
      );
    } catch (e) {
      _lessonCache.remove(lessonId);
      return null;
    }
  }

  static Future<List<EnhancedLesson>> getCachedLessons({int? limit}) async {
    final lessons = <EnhancedLesson>[];
    final caches = _lessonCache.values.toList();

    final limitedCaches = limit != null ? caches.take(limit) : caches;

    for (final cache in limitedCaches) {
      try {
        final lessonMap = jsonDecode(cache.lessonData);
        lessons.add(
          EnhancedLesson(
            id: lessonMap['id'],
            title: lessonMap['title'],
            subtitle: lessonMap['subtitle'],
            description: lessonMap['description'],
            content: lessonMap['content'],
            difficulty: LessonDifficulty.values.firstWhere(
              (d) => d.toString() == lessonMap['difficulty'],
              orElse: () => LessonDifficulty.beginner,
            ),
            estimatedDuration: lessonMap['estimatedDuration'],
            themeColor: Color(lessonMap['themeColor']),
            iconName: lessonMap['iconName'],
            tags: List<String>.from(lessonMap['tags'] ?? []),
            isFeatured: lessonMap['isFeatured'] ?? false,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              lessonMap['createdAt'],
            ),
            order: 1,
            analytics: LessonAnalytics(
              viewCount: 0,
              completionRate: 0.0,
              averageRating: 0.0,
              averageTimeSpent: 0,
              ratingCount: 0,
            ),
            learningObjectives: [],
            prerequisites: [],
            resources: [],
            questions: [],
          ),
        );
      } catch (e) {
        _lessonCache.remove(cache.lessonId);
      }
    }

    return lessons;
  }

  static Future<void> downloadLessonForOffline(String lessonId) async {
    // In production, this would download media assets and mark as downloaded
    final cache = _lessonCache[lessonId];
    if (cache != null) {
      _lessonCache[lessonId] = OfflineLessonCache(
        lessonId: cache.lessonId,
        lessonData: cache.lessonData,
        cachedAt: cache.cachedAt,
        isDownloaded: true,
      );
    }
  }

  // Progress synchronization
  static Future<void> saveProgressOffline(
    String userId,
    String lessonId,
    UserLessonProgress progress,
  ) async {
    final syncItem = OfflineProgressSync(
      id: '${userId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      lessonId: lessonId,
      progressData: jsonEncode(progress.toFirestore()),
      modifiedAt: DateTime.now(),
    );

    _progressCache[syncItem.id] = syncItem;
  }

  static Future<UserLessonProgress?> getOfflineProgress(
    String userId,
    String lessonId,
  ) async {
    final progressItems = _progressCache.values
        .where((item) => item.userId == userId && item.lessonId == lessonId)
        .toList();

    if (progressItems.isEmpty) return null;

    progressItems.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    final latest = progressItems.first;

    try {
      final progressMap = jsonDecode(latest.progressData);
      return UserLessonProgress.fromFirestore(
        FakeDocumentSnapshot(progressMap),
      );
    } catch (e) {
      return null;
    }
  }

  // Sync operations
  static Future<SyncResult> syncPendingProgress() async {
    if (!_isOnline) {
      return SyncResult(success: false, error: 'No internet connection');
    }

    final pendingItems = _progressCache.values
        .where((item) => item.status == SyncStatus.pending)
        .toList();

    int successCount = 0;
    int failureCount = 0;

    for (final item in pendingItems) {
      try {
        // Simulate sync to Firebase
        await Future.delayed(const Duration(milliseconds: 100));

        // Mark as synced
        _progressCache[item.id] = OfflineProgressSync(
          id: item.id,
          userId: item.userId,
          lessonId: item.lessonId,
          progressData: item.progressData,
          modifiedAt: item.modifiedAt,
          status: SyncStatus.synced,
        );

        successCount++;
      } catch (e) {
        failureCount++;
      }
    }

    _lastSyncTime = DateTime.now();

    return SyncResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  static Future<SyncResult> syncPendingQuizAttempts() async {
    // Simplified implementation
    return SyncResult(success: true, successCount: 0, failureCount: 0);
  }

  // Storage management
  static Future<void> clearExpiredCache({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    final expiredKeys = <String>[];

    for (final entry in _lessonCache.entries) {
      if (entry.value.cachedAt.isBefore(cutoffTime)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _lessonCache.remove(key);
    }
  }

  static Future<void> clearAllOfflineData() async {
    _lessonCache.clear();
    _progressCache.clear();
  }

  static OfflineStorageInfo getStorageInfo() {
    final totalLessons = _lessonCache.length;
    final downloadedLessons = _lessonCache.values
        .where((l) => l.isDownloaded)
        .length;
    final pendingSync = _progressCache.values
        .where((p) => p.status == SyncStatus.pending)
        .length;

    return OfflineStorageInfo(
      totalCachedLessons: totalLessons,
      downloadedLessons: downloadedLessons,
      pendingSyncItems: pendingSync,
      mediaAssets: 0, // Simplified
      lastSyncTime: _lastSyncTime,
    );
  }
}

// Helper classes
class SyncResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final String? error;

  SyncResult({
    required this.success,
    this.successCount = 0,
    this.failureCount = 0,
    this.error,
  });
}

class OfflineStorageInfo {
  final int totalCachedLessons;
  final int downloadedLessons;
  final int pendingSyncItems;
  final int mediaAssets;
  final DateTime? lastSyncTime;

  OfflineStorageInfo({
    required this.totalCachedLessons,
    required this.downloadedLessons,
    required this.pendingSyncItems,
    required this.mediaAssets,
    this.lastSyncTime,
  });
}

// Fake DocumentSnapshot for offline data
class FakeDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _data['id'] ?? '';

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
