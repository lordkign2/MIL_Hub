import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import './dashboard_event.dart';
import './dashboard_state.dart';
import '../../models/user_profile_model.dart';
import '../../services/user_service.dart';
import '../../services/offline_user_service.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
    on<LoadMoreActivitiesEvent>(_onLoadMoreActivities);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
    on<UpdateUserPreferencesEvent>(_onUpdateUserPreferences);
    on<AddUserActivityEvent>(_onAddUserActivity);
    on<ProfileDataChangedEvent>(_onProfileDataChanged);
    on<AnalyticsDataChangedEvent>(_onAnalyticsDataChanged);
    on<ActivitiesDataChangedEvent>(_onActivitiesDataChanged);
  }

  /// Handle loading initial dashboard data
  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

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
        emit(DashboardError(message: 'Failed to load user profile'));
        return;
      }

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

      // Load initial activities
      final activities = await UserService.getPaginatedUserActivities(
        limit: 10,
      );

      emit(
        DashboardLoaded(
          userProfile: profile,
          userAnalytics: analytics,
          activities: activities,
          hasMoreActivities: activities.length >= 10,
        ),
      );

      // Cache data for offline use with batch operations for better performance
      await OfflineUserService.batchCacheOperations([
        () => OfflineUserService.cacheUserProfile(profile),
        () => OfflineUserService.cacheUserAnalytics(profile.uid, analytics),
        () =>
            OfflineUserService.cacheUserActivities(profile.uid, activities, 1),
      ]);

      // Prefetch additional data in the background for better performance
      Future.delayed(Duration.zero, () {
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
            emit(
              DashboardLoaded(
                userProfile: cachedProfile,
                userAnalytics: cachedAnalytics,
                activities: cachedActivities,
                hasMoreActivities: cachedActivities.length >= 10,
              ),
            );
            return;
          }
        }
      } catch (offlineError) {
        // Ignore offline errors
      }

      emit(DashboardError(message: 'Failed to load dashboard data: $e'));
    }
  }

  /// Handle refreshing dashboard data
  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(
        DashboardRefreshing(
          userProfile: currentState.userProfile,
          userAnalytics: currentState.userAnalytics,
          activities: currentState.activities,
        ),
      );

      try {
        // Reload all data
        await _onLoadDashboard(LoadDashboardEvent(), emit);
      } catch (e) {
        emit(DashboardError(message: 'Failed to refresh dashboard data: $e'));
      }
    } else {
      // If not loaded yet, just load the data
      await _onLoadDashboard(LoadDashboardEvent(), emit);
    }
  }

  /// Handle loading more activities
  Future<void> _onLoadMoreActivities(
    LoadMoreActivitiesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;

      // Don't load more if we already know there are no more activities
      if (!currentState.hasMoreActivities) return;

      emit(
        DashboardLoadingMore(
          userProfile: currentState.userProfile,
          userAnalytics: currentState.userAnalytics,
          activities: currentState.activities,
        ),
      );

      try {
        final lastActivity = currentState.activities.isNotEmpty
            ? currentState.activities.last
            : null;

        // In a real implementation, you would track the last document for pagination
        // final DocumentSnapshot? lastDocument = null;

        final newActivities = await UserService.getPaginatedUserActivities(
          limit: 10,
          // lastDocument: lastDocument, // Disabled for now
        );

        emit(
          currentState.copyWith(
            activities: [...currentState.activities, ...newActivities],
            hasMoreActivities: newActivities.length >= 10,
          ),
        );
      } catch (e) {
        emit(DashboardError(message: 'Failed to load more activities: $e'));
      }
    }
  }

  /// Handle updating user profile
  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await UserService.createOrUpdateUserProfile(event.profile);

      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(userProfile: event.profile));
      }
    } catch (e) {
      emit(DashboardError(message: 'Failed to update profile: $e'));
    }
  }

  /// Handle updating user preferences
  Future<void> _onUpdateUserPreferences(
    UpdateUserPreferencesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await UserService.updateUserPreferences(event.preferences);

      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        final updatedProfile = currentState.userProfile.copyWith(
          preferences: event.preferences,
        );
        emit(currentState.copyWith(userProfile: updatedProfile));
      }
    } catch (e) {
      emit(DashboardError(message: 'Failed to update preferences: $e'));
    }
  }

  /// Handle adding user activity
  Future<void> _onAddUserActivity(
    AddUserActivityEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await UserService.addUserActivity(event.activity);

      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(
          currentState.copyWith(
            activities: [event.activity, ...currentState.activities],
          ),
        );
      }
    } catch (e) {
      emit(DashboardError(message: 'Failed to add activity: $e'));
    }
  }

  /// Handle profile data changes
  void _onProfileDataChanged(
    ProfileDataChangedEvent event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(userProfile: event.profile));
    }
  }

  /// Handle analytics data changes
  void _onAnalyticsDataChanged(
    AnalyticsDataChangedEvent event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(userAnalytics: event.analytics));
    }
  }

  /// Handle activities data changes
  void _onActivitiesDataChanged(
    ActivitiesDataChangedEvent event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(
        currentState.copyWith(
          activities: event.activities,
          hasMoreActivities: event.hasMoreActivities,
        ),
      );
    }
  }
}
