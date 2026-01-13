// Offline User Service for Dashboard Data
// Provides caching and offline capabilities for user profile, analytics, and activities

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

// Simplified storage models for offline caching
class OfflineUserProfileCache {
  final String userId;
  final String profileData;
  final DateTime cachedAt;
  final bool isComplete;

  OfflineUserProfileCache({
    required this.userId,
    required this.profileData,
    required this.cachedAt,
    this.isComplete = true,
  });
}

class OfflineUserAnalyticsCache {
  final String userId;
  final String analyticsData;
  final DateTime cachedAt;

  OfflineUserAnalyticsCache({
    required this.userId,
    required this.analyticsData,
    required this.cachedAt,
  });
}

class OfflineUserActivityCache {
  final String userId;
  final String activitiesData;
  final DateTime cachedAt;
  final int page;

  OfflineUserActivityCache({
    required this.userId,
    required this.activitiesData,
    required this.cachedAt,
    required this.page,
  });
}

class OfflineSyncItem {
  final String id;
  final String userId;
  final String itemType;
  final String itemData;
  final DateTime modifiedAt;
  final SyncStatus status;

  OfflineSyncItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemData,
    required this.modifiedAt,
    this.status = SyncStatus.pending,
  });
}

enum SyncStatus { pending, syncing, synced, failed }

// Main Offline User Service
class OfflineUserService {
  static const String _prefsKeyPrefix = 'offline_user_';
  static const String _profileCacheKey = '${_prefsKeyPrefix}profile_cache';
  static const String _analyticsCacheKey = '${_prefsKeyPrefix}analytics_cache';
  static const String _activitiesCacheKey =
      '${_prefsKeyPrefix}activities_cache';
  static const String _syncQueueKey = '${_prefsKeyPrefix}sync_queue';

  static bool _isOnline = true;
  static DateTime? _lastSyncTime;

  static Future<void> initialize() async {
    // Initialize shared preferences for offline storage
    print('Offline User Service initialized');
  }

  // Connectivity management
  static bool get isOnline => _isOnline;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static void setOnlineStatus(bool online) {
    _isOnline = online;
  }

  // Profile caching
  static Future<void> cacheUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = OfflineUserProfileCache(
        userId: profile.uid,
        profileData: jsonEncode(profile.toFirestore()),
        cachedAt: DateTime.now(),
      );

      final cacheData = {
        'userId': cache.userId,
        'profileData': cache.profileData,
        'cachedAt': cache.cachedAt.millisecondsSinceEpoch,
      };

      await prefs.setString(_profileCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching user profile: $e');
    }
  }

  static Future<UserProfile?> getCachedUserProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_profileCacheKey);

      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      final cache = OfflineUserProfileCache(
        userId: cacheData['userId'],
        profileData: cacheData['profileData'],
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cacheData['cachedAt']),
      );

      // Check if cache is still valid (less than 1 day old)
      if (DateTime.now().difference(cache.cachedAt).inDays > 1) {
        await prefs.remove(_profileCacheKey);
        return null;
      }

      final profileMap = jsonDecode(cache.profileData);
      return UserProfile.fromFirestore(FakeDocumentSnapshot(profileMap));
    } catch (e) {
      print('Error retrieving cached user profile: $e');
      return null;
    }
  }

  // Analytics caching
  static Future<void> cacheUserAnalytics(
    String userId,
    UserAnalytics analytics,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = OfflineUserAnalyticsCache(
        userId: userId,
        analyticsData: jsonEncode({
          'totalActivities': analytics.totalActivities,
          'weeklyActivities': analytics.weeklyActivities,
          'monthlyActivities': analytics.monthlyActivities,
          'currentStreak': analytics.currentStreak,
          'longestStreak': analytics.longestStreak,
          'totalTimeSpent': analytics.totalTimeSpent,
          'averageScore': analytics.averageScore,
          'level': analytics.level,
          'joinedDays': analytics.joinedDays,
          'lastActiveAgo': analytics.lastActiveAgo,
        }),
        cachedAt: DateTime.now(),
      );

      final cacheData = {
        'userId': cache.userId,
        'analyticsData': cache.analyticsData,
        'cachedAt': cache.cachedAt.millisecondsSinceEpoch,
      };

      await prefs.setString(_analyticsCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching user analytics: $e');
    }
  }

  static Future<UserAnalytics?> getCachedUserAnalytics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_analyticsCacheKey);

      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      final cache = OfflineUserAnalyticsCache(
        userId: cacheData['userId'],
        analyticsData: cacheData['analyticsData'],
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cacheData['cachedAt']),
      );

      // Check if cache is still valid (less than 1 hour old)
      if (DateTime.now().difference(cache.cachedAt).inHours > 1) {
        await prefs.remove(_analyticsCacheKey);
        return null;
      }

      final analyticsMap = jsonDecode(cache.analyticsData);
      return UserAnalytics(
        totalActivities: analyticsMap['totalActivities'],
        weeklyActivities: analyticsMap['weeklyActivities'],
        monthlyActivities: analyticsMap['monthlyActivities'],
        currentStreak: analyticsMap['currentStreak'],
        longestStreak: analyticsMap['longestStreak'],
        totalTimeSpent: analyticsMap['totalTimeSpent'],
        averageScore: analyticsMap['averageScore'].toDouble(),
        level: analyticsMap['level'],
        joinedDays: analyticsMap['joinedDays'],
        lastActiveAgo: analyticsMap['lastActiveAgo'],
      );
    } catch (e) {
      print('Error retrieving cached user analytics: $e');
      return null;
    }
  }

  // Activities caching
  static Future<void> cacheUserActivities(
    String userId,
    List<UserActivity> activities,
    int page,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert activities to serializable format
      final activitiesData = activities.map((activity) {
        return {
          'id': activity.id,
          'type': activity.type.toString().split('.').last,
          'title': activity.title,
          'description': activity.description,
          'timestamp': activity.timestamp.millisecondsSinceEpoch,
          'metadata': activity.metadata,
        };
      }).toList();

      final cache = OfflineUserActivityCache(
        userId: userId,
        activitiesData: jsonEncode(activitiesData),
        cachedAt: DateTime.now(),
        page: page,
      );

      final cacheData = {
        'userId': cache.userId,
        'activitiesData': cache.activitiesData,
        'cachedAt': cache.cachedAt.millisecondsSinceEpoch,
        'page': cache.page,
      };

      // Store with page-specific key
      final pageKey = '${_activitiesCacheKey}_page_$page';
      await prefs.setString(pageKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching user activities: $e');
    }
  }

  static Future<List<UserActivity>?> getCachedUserActivities(
    String userId,
    int page,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageKey = '${_activitiesCacheKey}_page_$page';
      final cacheString = prefs.getString(pageKey);

      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      final cache = OfflineUserActivityCache(
        userId: cacheData['userId'],
        activitiesData: cacheData['activitiesData'],
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cacheData['cachedAt']),
        page: cacheData['page'],
      );

      // Check if cache is still valid (less than 30 minutes old)
      if (DateTime.now().difference(cache.cachedAt).inMinutes > 30) {
        await prefs.remove(pageKey);
        return null;
      }

      final activitiesData = jsonDecode(cache.activitiesData) as List<dynamic>;
      final activities = activitiesData.map((data) {
        return UserActivity(
          id: data['id'] ?? '',
          type: ActivityType.values.firstWhere(
            (t) => t.toString() == 'ActivityType.${data['type']}',
            orElse: () => ActivityType.other,
          ),
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();

      return activities;
    } catch (e) {
      print('Error retrieving cached user activities: $e');
      return null;
    }
  }

  // Sync operations
  static Future<SyncResult> syncPendingChanges() async {
    if (!_isOnline) {
      return SyncResult(success: false, error: 'No internet connection');
    }

    try {
      // In a real implementation, this would sync pending profile updates,
      // preference changes, etc. to Firebase
      await Future.delayed(const Duration(milliseconds: 500));

      _lastSyncTime = DateTime.now();
      return SyncResult(success: true, successCount: 0, failureCount: 0);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  // Storage management
  static Future<void> clearExpiredCache() async {
    // SharedPreferences automatically manages expiration through our retrieval logic
    // This is a placeholder for more complex cache management
  }

  // Enhanced cache management with batch operations
  static Future<Map<String, dynamic>> getAllCachedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve all cached data for a user
      final profile = await getCachedUserProfile(userId);
      final analytics = await getCachedUserAnalytics(userId);

      // Retrieve all cached activity pages
      final List<List<UserActivity>> allActivities = [];
      int page = 1;

      while (true) {
        final activities = await getCachedUserActivities(userId, page);
        if (activities == null || activities.isEmpty) break;
        allActivities.add(activities);
        page++;
      }

      // Flatten all activities
      final flattenedActivities = allActivities.expand((list) => list).toList();

      return {
        'profile': profile,
        'analytics': analytics,
        'activities': flattenedActivities,
      };
    } catch (e) {
      print('Error retrieving all cached data: $e');
      return {};
    }
  }

  // Batch cache operations for better performance
  static Future<void> batchCacheOperations(
    List<Future<void> Function()> operations,
  ) async {
    try {
      // Execute all cache operations in sequence
      for (final operation in operations) {
        await operation();
      }
    } catch (e) {
      print('Error in batch cache operations: $e');
    }
  }

  // Prefetch and cache data for better performance
  static Future<void> prefetchAndCacheUserData(String userId) async {
    try {
      // In a real implementation, this would prefetch data based on user behavior patterns
      // For now, we'll just ensure the basic data is cached
      print('Prefetching user data for user: $userId');

      // This would typically run in the background to prepare data for future use
      // Implementation would depend on user behavior analytics and usage patterns
    } catch (e) {
      print('Error prefetching user data: $e');
    }
  }

  // Cache warming - preload frequently accessed data
  static Future<void> warmUpCache(String userId) async {
    try {
      print('Warming up cache for user: $userId');

      // Check if we have valid cached data
      final profileValid = await isCacheValid(
        _profileCacheKey,
        const Duration(hours: 12),
      );

      final analyticsValid = await isCacheValid(
        _analyticsCacheKey,
        const Duration(minutes: 30),
      );

      // If cache is not valid, fetch fresh data in background
      if (!profileValid || !analyticsValid) {
        print('Cache warming: Fetching fresh data for user $userId');
        // This would trigger background data fetching to populate cache
        // Implementation would depend on specific use cases
      }
    } catch (e) {
      print('Error warming up cache: $e');
    }
  }

  // Get cache statistics for monitoring
  static Future<CacheStats> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Count cached items
      int profileCount = 0;
      int analyticsCount = 0;
      int activityPageCount = 0;

      // Check for profile cache
      if (prefs.getString(_profileCacheKey) != null) {
        profileCount = 1;
      }

      // Check for analytics cache
      if (prefs.getString(_analyticsCacheKey) != null) {
        analyticsCount = 1;
      }

      // Count activity pages
      for (int i = 1; i <= 50; i++) {
        if (prefs.getString('${_activitiesCacheKey}_page_$i') != null) {
          activityPageCount++;
        }
      }

      return CacheStats(
        profileCount: profileCount,
        analyticsCount: analyticsCount,
        activityPageCount: activityPageCount,
        totalItems: profileCount + analyticsCount + activityPageCount,
      );
    } catch (e) {
      print('Error getting cache stats: $e');
      return CacheStats(
        profileCount: 0,
        analyticsCount: 0,
        activityPageCount: 0,
        totalItems: 0,
      );
    }
  }

  // Smart cache invalidation based on data freshness
  static Future<bool> isCacheValid(String cacheKey, Duration maxAge) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(cacheKey);

      if (cacheString == null) return false;

      final cacheData = jsonDecode(cacheString);
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(
        cacheData['cachedAt'],
      );

      return DateTime.now().difference(cachedAt).compareTo(maxAge) < 0;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  static Future<void> clearAllOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
    await prefs.remove(_analyticsCacheKey);
    await prefs.remove(_activitiesCacheKey);

    // Clear all page-specific activity caches
    for (int i = 0; i < 100; i++) {
      await prefs.remove('${_activitiesCacheKey}_page_$i');
    }
  }

  static OfflineStorageInfo getStorageInfo() {
    // In a real implementation, this would return actual storage usage
    return OfflineStorageInfo(
      totalCachedProfiles: 1,
      totalCachedAnalytics: 1,
      totalCachedActivityPages: 5,
      pendingSyncItems: 0,
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
  final int totalCachedProfiles;
  final int totalCachedAnalytics;
  final int totalCachedActivityPages;
  final int pendingSyncItems;
  final DateTime? lastSyncTime;

  OfflineStorageInfo({
    required this.totalCachedProfiles,
    required this.totalCachedAnalytics,
    required this.totalCachedActivityPages,
    required this.pendingSyncItems,
    this.lastSyncTime,
  });
}

// Cache statistics model
class CacheStats {
  final int profileCount;
  final int analyticsCount;
  final int activityPageCount;
  final int totalItems;

  CacheStats({
    required this.profileCount,
    required this.analyticsCount,
    required this.activityPageCount,
    required this.totalItems,
  });

  double get hitRate =>
      totalItems > 0 ? totalItems / 100.0 : 0.0; // Simplified calculation
}

// Fake DocumentSnapshot for offline data
class FakeDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _data['uid'] ?? '';

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
