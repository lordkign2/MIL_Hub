import 'package:equatable/equatable.dart';
import '../../models/user_profile_model.dart';

/// Base class for all dashboard events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial dashboard data
class LoadDashboardEvent extends DashboardEvent {
  const LoadDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to refresh dashboard data
class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load more activities
class LoadMoreActivitiesEvent extends DashboardEvent {
  const LoadMoreActivitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Event to update user profile
class UpdateUserProfileEvent extends DashboardEvent {
  final UserProfile profile;

  const UpdateUserProfileEvent({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Event to update user preferences
class UpdateUserPreferencesEvent extends DashboardEvent {
  final UserPreferences preferences;

  const UpdateUserPreferencesEvent({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

/// Event to add user activity
class AddUserActivityEvent extends DashboardEvent {
  final UserActivity activity;

  const AddUserActivityEvent({required this.activity});

  @override
  List<Object?> get props => [activity];
}

/// Event triggered when profile data changes
class ProfileDataChangedEvent extends DashboardEvent {
  final UserProfile profile;

  const ProfileDataChangedEvent({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Event triggered when analytics data changes
class AnalyticsDataChangedEvent extends DashboardEvent {
  final UserAnalytics analytics;

  const AnalyticsDataChangedEvent({required this.analytics});

  @override
  List<Object?> get props => [analytics];
}

/// Event triggered when activities data changes
class ActivitiesDataChangedEvent extends DashboardEvent {
  final List<UserActivity> activities;
  final bool hasMoreActivities;

  const ActivitiesDataChangedEvent({
    required this.activities,
    required this.hasMoreActivities,
  });

  @override
  List<Object?> get props => [activities, hasMoreActivities];
}
