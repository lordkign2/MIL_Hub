import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import '../../models/user_profile_model.dart';
import '../../services/user_service.dart';
import '../../services/offline_user_service.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  UserProfile? _userProfile;
  UserAnalytics? _userAnalytics;
  List<UserActivity> _activities = [];
  bool _hasMoreActivities = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  UserProfile? get userProfile => _userProfile;
  UserAnalytics? get userAnalytics => _userAnalytics;
  List<UserActivity> get activities => _activities;
  bool get hasMoreActivities => _hasMoreActivities;

  // Load initial dashboard data
  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Warm up cache in background
      final currentUser = UserService.auth.currentUser;
      if (currentUser != null) {
        OfflineUserService.warmUpCache(currentUser.uid);
      }

      // Load user profile
      final profileStream = UserService.getCurrentUserProfile();
      final profileCompleter = Completer<UserProfile?>();

      final profileSubscription = profileStream.listen(
        (profile) {
          if (!profileCompleter.isCompleted) {
            profileCompleter.complete(profile);
          }
        },
        onError: (error) {
          if (!profileCompleter.isCompleted) {
            profileCompleter.completeError(error);
          }
        },
      );

      final profile = await profileCompleter.future;
      profileSubscription.cancel();

      if (profile == null) {
        _errorMessage = 'Failed to load user profile';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _userProfile = profile;

      // Load user analytics
      final analyticsStream = UserService.streamUserAnalytics();
      final analyticsCompleter = Completer<UserAnalytics>();

      final analyticsSubscription = analyticsStream.listen(
        (analytics) {
          if (!analyticsCompleter.isCompleted) {
            analyticsCompleter.complete(analytics);
          }
        },
        onError: (error) {
          if (!analyticsCompleter.isCompleted) {
            analyticsCompleter.completeError(error);
          }
        },
      );

      final analytics = await analyticsCompleter.future;
      analyticsSubscription.cancel();

      _userAnalytics = analytics;

      // Load initial activities
      final activities = await UserService.getPaginatedUserActivities(
        limit: 10,
      );
      _activities = activities;
      _hasMoreActivities = activities.length >= 10;

      // Cache data for offline use with batch operations for better performance
      await OfflineUserService.batchCacheOperations([
        () => OfflineUserService.cacheUserProfile(profile),
        () => OfflineUserService.cacheUserAnalytics(profile.uid, analytics),
        () =>
            OfflineUserService.cacheUserActivities(profile.uid, activities, 1),
      ]);

      _isLoading = false;
      notifyListeners();

      // Prefetch additional data in the background for better performance
      SchedulerBinding.instance.addPostFrameCallback((_) {
        OfflineUserService.prefetchAndCacheUserData(profile.uid);
      });
    } catch (e) {
      // Try to load from offline cache as fallback
      try {
        final currentUser = UserService.auth.currentUser;
        if (currentUser != null) {
          final cachedProfile = await OfflineUserService.getCachedUserProfile(
            currentUser.uid,
          );
          final cachedAnalytics =
              await OfflineUserService.getCachedUserAnalytics(currentUser.uid);
          final cachedActivities =
              await OfflineUserService.getCachedUserActivities(
                currentUser.uid,
                1,
              );

          if (cachedProfile != null &&
              cachedAnalytics != null &&
              cachedActivities != null) {
            _userProfile = cachedProfile;
            _userAnalytics = cachedAnalytics;
            _activities = cachedActivities;
            _hasMoreActivities = cachedActivities.length >= 10;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (offlineError) {
        // Ignore offline errors
      }

      _errorMessage = 'Failed to load dashboard data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Reload all data
      await loadDashboard();
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh dashboard data: $e';
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Load more activities with retry mechanism
  Future<void> loadMoreActivities({int retryCount = 0}) async {
    if (_isLoadingMore || !_hasMoreActivities) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real implementation, you would track the last document for pagination
      // final DocumentSnapshot? lastDocument = null;

      final newActivities = await UserService.getPaginatedUserActivities(
        limit: 10,
        // lastDocument: lastDocument, // Disabled for now
      );

      _activities = [..._activities, ...newActivities];
      _hasMoreActivities = newActivities.length >= 10;

      // Cache new activities
      final currentUser = UserService.auth.currentUser;
      if (currentUser != null) {
        final pageNumber = (_activities.length ~/ 10) + 1;
        await OfflineUserService.cacheUserActivities(
          currentUser.uid,
          newActivities,
          pageNumber,
        );
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      // Implement retry mechanism with exponential backoff
      if (retryCount < 3) {
        final delay = Duration(milliseconds: 1000 * (retryCount + 1));
        print(
          'Retrying loadMoreActivities in ${delay.inMilliseconds}ms (attempt ${retryCount + 1})',
        );
        await Future.delayed(delay);
        return await loadMoreActivities(retryCount: retryCount + 1);
      }

      _errorMessage = 'Failed to load more activities: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await UserService.createOrUpdateUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    try {
      await UserService.updateUserPreferences(preferences);
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(preferences: preferences);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update preferences: $e';
      notifyListeners();
    }
  }

  // Add user activity
  Future<void> addUserActivity(UserActivity activity) async {
    try {
      await UserService.addUserActivity(activity);
      _activities = [activity, ..._activities];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add activity: $e';
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
