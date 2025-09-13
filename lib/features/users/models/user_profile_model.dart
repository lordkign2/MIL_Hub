import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced User Profile Model
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? bio;
  final DateTime joinedDate;
  final DateTime lastActiveDate;
  final UserRole role;
  final UserPreferences preferences;
  final UserStats stats;
  final List<String> interests;
  final Map<String, dynamic> achievements;
  final UserSubscription subscription;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.bio,
    required this.joinedDate,
    required this.lastActiveDate,
    this.role = UserRole.student,
    required this.preferences,
    required this.stats,
    required this.interests,
    required this.achievements,
    required this.subscription,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      bio: data['bio'],
      joinedDate:
          (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveDate:
          (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: UserRole.values.firstWhere(
        (r) => r.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.student,
      ),
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      interests: List<String>.from(data['interests'] ?? []),
      achievements: Map<String, dynamic>.from(data['achievements'] ?? {}),
      subscription: UserSubscription.fromMap(data['subscription'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'bio': bio,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'role': role.toString().split('.').last,
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
      'interests': interests,
      'achievements': achievements,
      'subscription': subscription.toMap(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? bio,
    DateTime? joinedDate,
    DateTime? lastActiveDate,
    UserRole? role,
    UserPreferences? preferences,
    UserStats? stats,
    List<String>? interests,
    Map<String, dynamic>? achievements,
    UserSubscription? subscription,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      joinedDate: joinedDate ?? this.joinedDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      interests: interests ?? this.interests,
      achievements: achievements ?? this.achievements,
      subscription: subscription ?? this.subscription,
    );
  }
}

enum UserRole { student, educator, admin, moderator }

// User Preferences Model
class UserPreferences {
  final bool darkMode;
  final String language;
  final bool notifications;
  final bool emailDigest;
  final bool pushNotifications;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final LearningPreferences learningPreferences;
  final AccessibilitySettings accessibilitySettings;

  UserPreferences({
    this.darkMode = true,
    this.language = 'en',
    this.notifications = true,
    this.emailDigest = true,
    this.pushNotifications = true,
    required this.notificationSettings,
    required this.privacySettings,
    required this.learningPreferences,
    required this.accessibilitySettings,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      darkMode: data['darkMode'] ?? true,
      language: data['language'] ?? 'en',
      notifications: data['notifications'] ?? true,
      emailDigest: data['emailDigest'] ?? true,
      pushNotifications: data['pushNotifications'] ?? true,
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] ?? {},
      ),
      privacySettings: PrivacySettings.fromMap(data['privacySettings'] ?? {}),
      learningPreferences: LearningPreferences.fromMap(
        data['learningPreferences'] ?? {},
      ),
      accessibilitySettings: AccessibilitySettings.fromMap(
        data['accessibilitySettings'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'language': language,
      'notifications': notifications,
      'emailDigest': emailDigest,
      'pushNotifications': pushNotifications,
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'learningPreferences': learningPreferences.toMap(),
      'accessibilitySettings': accessibilitySettings.toMap(),
    };
  }
}

// Notification Settings
class NotificationSettings {
  final bool achievementUnlocked;
  final bool streakReminder;
  final bool weeklyProgress;
  final bool communityUpdates;
  final bool systemUpdates;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;

  NotificationSettings({
    this.achievementUnlocked = true,
    this.streakReminder = true,
    this.weeklyProgress = true,
    this.communityUpdates = true,
    this.systemUpdates = true,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 8, minute: 0),
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> data) {
    return NotificationSettings(
      achievementUnlocked: data['achievementUnlocked'] ?? true,
      streakReminder: data['streakReminder'] ?? true,
      weeklyProgress: data['weeklyProgress'] ?? true,
      communityUpdates: data['communityUpdates'] ?? true,
      systemUpdates: data['systemUpdates'] ?? true,
      quietHoursStart: TimeOfDay(
        hour: data['quietHoursStart']?['hour'] ?? 22,
        minute: data['quietHoursStart']?['minute'] ?? 0,
      ),
      quietHoursEnd: TimeOfDay(
        hour: data['quietHoursEnd']?['hour'] ?? 8,
        minute: data['quietHoursEnd']?['minute'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementUnlocked': achievementUnlocked,
      'streakReminder': streakReminder,
      'weeklyProgress': weeklyProgress,
      'communityUpdates': communityUpdates,
      'systemUpdates': systemUpdates,
      'quietHoursStart': {
        'hour': quietHoursStart.hour,
        'minute': quietHoursStart.minute,
      },
      'quietHoursEnd': {
        'hour': quietHoursEnd.hour,
        'minute': quietHoursEnd.minute,
      },
    };
  }
}

// Privacy Settings
class PrivacySettings {
  final bool profileVisible;
  final bool activityVisible;
  final bool achievementsVisible;
  final bool allowFriendRequests;
  final bool allowMessages;
  final bool showOnlineStatus;
  final bool dataSharing;

  PrivacySettings({
    this.profileVisible = true,
    this.activityVisible = true,
    this.achievementsVisible = true,
    this.allowFriendRequests = true,
    this.allowMessages = true,
    this.showOnlineStatus = true,
    this.dataSharing = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> data) {
    return PrivacySettings(
      profileVisible: data['profileVisible'] ?? true,
      activityVisible: data['activityVisible'] ?? true,
      achievementsVisible: data['achievementsVisible'] ?? true,
      allowFriendRequests: data['allowFriendRequests'] ?? true,
      allowMessages: data['allowMessages'] ?? true,
      showOnlineStatus: data['showOnlineStatus'] ?? true,
      dataSharing: data['dataSharing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisible': profileVisible,
      'activityVisible': activityVisible,
      'achievementsVisible': achievementsVisible,
      'allowFriendRequests': allowFriendRequests,
      'allowMessages': allowMessages,
      'showOnlineStatus': showOnlineStatus,
      'dataSharing': dataSharing,
    };
  }
}

// Learning Preferences
class LearningPreferences {
  final String preferredDifficulty;
  final List<String> favoriteTopics;
  final int dailyGoal;
  final bool adaptiveLearning;
  final bool gamificationEnabled;
  final String learningStyle;
  final TimeOfDay preferredStudyTime;

  LearningPreferences({
    this.preferredDifficulty = 'intermediate',
    required this.favoriteTopics,
    this.dailyGoal = 30,
    this.adaptiveLearning = true,
    this.gamificationEnabled = true,
    this.learningStyle = 'visual',
    this.preferredStudyTime = const TimeOfDay(hour: 18, minute: 0),
  });

  factory LearningPreferences.fromMap(Map<String, dynamic> data) {
    return LearningPreferences(
      preferredDifficulty: data['preferredDifficulty'] ?? 'intermediate',
      favoriteTopics: List<String>.from(data['favoriteTopics'] ?? []),
      dailyGoal: data['dailyGoal'] ?? 30,
      adaptiveLearning: data['adaptiveLearning'] ?? true,
      gamificationEnabled: data['gamificationEnabled'] ?? true,
      learningStyle: data['learningStyle'] ?? 'visual',
      preferredStudyTime: TimeOfDay(
        hour: data['preferredStudyTime']?['hour'] ?? 18,
        minute: data['preferredStudyTime']?['minute'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredDifficulty': preferredDifficulty,
      'favoriteTopics': favoriteTopics,
      'dailyGoal': dailyGoal,
      'adaptiveLearning': adaptiveLearning,
      'gamificationEnabled': gamificationEnabled,
      'learningStyle': learningStyle,
      'preferredStudyTime': {
        'hour': preferredStudyTime.hour,
        'minute': preferredStudyTime.minute,
      },
    };
  }
}

// Accessibility Settings
class AccessibilitySettings {
  final bool highContrast;
  final double fontSize;
  final bool reduceMotion;
  final bool screenReader;
  final bool voiceCommands;
  final String colorBlindSupport;

  AccessibilitySettings({
    this.highContrast = false,
    this.fontSize = 16.0,
    this.reduceMotion = false,
    this.screenReader = false,
    this.voiceCommands = false,
    this.colorBlindSupport = 'none',
  });

  factory AccessibilitySettings.fromMap(Map<String, dynamic> data) {
    return AccessibilitySettings(
      highContrast: data['highContrast'] ?? false,
      fontSize: (data['fontSize'] ?? 16.0).toDouble(),
      reduceMotion: data['reduceMotion'] ?? false,
      screenReader: data['screenReader'] ?? false,
      voiceCommands: data['voiceCommands'] ?? false,
      colorBlindSupport: data['colorBlindSupport'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'highContrast': highContrast,
      'fontSize': fontSize,
      'reduceMotion': reduceMotion,
      'screenReader': screenReader,
      'voiceCommands': voiceCommands,
      'colorBlindSupport': colorBlindSupport,
    };
  }
}

// User Statistics
class UserStats {
  final int totalLessonsCompleted;
  final int totalTimeSpent;
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final int level;
  final double averageQuizScore;
  final Map<String, int> categoryProgress;
  final List<DateTime> activityHistory;
  final int totalLogins;
  final DateTime lastLogin;

  UserStats({
    this.totalLessonsCompleted = 0,
    this.totalTimeSpent = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPoints = 0,
    this.level = 1,
    this.averageQuizScore = 0.0,
    required this.categoryProgress,
    required this.activityHistory,
    this.totalLogins = 0,
    required this.lastLogin,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      totalLessonsCompleted: data['totalLessonsCompleted'] ?? 0,
      totalTimeSpent: data['totalTimeSpent'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      level: data['level'] ?? 1,
      averageQuizScore: (data['averageQuizScore'] ?? 0.0).toDouble(),
      categoryProgress: Map<String, int>.from(data['categoryProgress'] ?? {}),
      activityHistory:
          (data['activityHistory'] as List<dynamic>?)
              ?.map((date) => (date as Timestamp).toDate())
              .toList() ??
          [],
      totalLogins: data['totalLogins'] ?? 0,
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalTimeSpent': totalTimeSpent,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalPoints': totalPoints,
      'level': level,
      'averageQuizScore': averageQuizScore,
      'categoryProgress': categoryProgress,
      'activityHistory': activityHistory
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      'totalLogins': totalLogins,
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }
}

// User Subscription
class UserSubscription {
  final SubscriptionType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String> features;
  final double? price;
  final String? transactionId;

  UserSubscription({
    this.type = SubscriptionType.free,
    this.startDate,
    this.endDate,
    this.isActive = false,
    required this.features,
    this.price,
    this.transactionId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> data) {
    return UserSubscription(
      type: SubscriptionType.values.firstWhere(
        (t) => t.toString() == 'SubscriptionType.${data['type']}',
        orElse: () => SubscriptionType.free,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      features: List<String>.from(data['features'] ?? []),
      price: data['price']?.toDouble(),
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'features': features,
      'price': price,
      'transactionId': transactionId,
    };
  }

  bool get isPremium => type != SubscriptionType.free && isActive;
}

enum SubscriptionType { free, basic, premium, pro }
