import 'package:equatable/equatable.dart';
import '../../models/user_profile_model.dart';

/// Base class for all dashboard states
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state
class DashboardLoading extends DashboardState {
  const DashboardLoading();

  @override
  List<Object?> get props => [];
}

/// Loaded state with all dashboard data
class DashboardLoaded extends DashboardState {
  final UserProfile userProfile;
  final UserAnalytics userAnalytics;
  final List<UserActivity> activities;
  final bool hasMoreActivities;

  const DashboardLoaded({
    required this.userProfile,
    required this.userAnalytics,
    required this.activities,
    required this.hasMoreActivities,
  });

  @override
  List<Object?> get props => [
    userProfile,
    userAnalytics,
    activities,
    hasMoreActivities,
  ];

  DashboardLoaded copyWith({
    UserProfile? userProfile,
    UserAnalytics? userAnalytics,
    List<UserActivity>? activities,
    bool? hasMoreActivities,
  }) {
    return DashboardLoaded(
      userProfile: userProfile ?? this.userProfile,
      userAnalytics: userAnalytics ?? this.userAnalytics,
      activities: activities ?? this.activities,
      hasMoreActivities: hasMoreActivities ?? this.hasMoreActivities,
    );
  }
}

/// Error state
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading more activities state
class DashboardLoadingMore extends DashboardState {
  final UserProfile userProfile;
  final UserAnalytics userAnalytics;
  final List<UserActivity> activities;

  const DashboardLoadingMore({
    required this.userProfile,
    required this.userAnalytics,
    required this.activities,
  });

  @override
  List<Object?> get props => [userProfile, userAnalytics, activities];
}

/// Refreshing state
class DashboardRefreshing extends DashboardState {
  final UserProfile userProfile;
  final UserAnalytics userAnalytics;
  final List<UserActivity> activities;

  const DashboardRefreshing({
    required this.userProfile,
    required this.userAnalytics,
    required this.activities,
  });

  @override
  List<Object?> get props => [userProfile, userAnalytics, activities];
}
