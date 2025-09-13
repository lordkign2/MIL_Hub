import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  // Collections
  static final CollectionReference usersCollection = _firestore.collection(
    'users',
  );
  static final CollectionReference _userActivitiesCollection = _firestore
      .collection('userActivities');
  static final CollectionReference _userSettingsCollection = _firestore
      .collection('userSettings');

  // Get current user profile
  static Stream<UserProfile?> getCurrentUserProfile() {
    final user = auth.currentUser;
    if (user == null) return Stream.value(null);

    return usersCollection.doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Create or update user profile
  static Future<void> createOrUpdateUserProfile(UserProfile profile) async {
    try {
      await usersCollection
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update profile photo
  static Future<void> updateProfilePhoto(String photoURL) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Update Firebase Auth profile
      await user.updatePhotoURL(photoURL);

      // Update Firestore profile
      await usersCollection.doc(user.uid).update({
        'photoURL': photoURL,
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update profile photo: $e');
    }
  }

  // Update display name
  static Future<void> updateDisplayName(String displayName) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);

      // Update Firestore profile
      await usersCollection.doc(user.uid).update({
        'displayName': displayName,
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  // Update user preferences
  static Future<void> updateUserPreferences(UserPreferences preferences) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await usersCollection.doc(user.uid).update({
        'preferences': preferences.toMap(),
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Update user stats
  static Future<void> updateUserStats(UserStats stats) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await usersCollection.doc(user.uid).update({
        'stats': stats.toMap(),
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  // Add user activity
  static Future<void> addUserActivity(UserActivity activity) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _userActivitiesCollection.add({
        'userId': user.uid,
        'type': activity.type.toString().split('.').last,
        'title': activity.title,
        'description': activity.description,
        'timestamp': Timestamp.fromDate(activity.timestamp),
        'metadata': activity.metadata,
      });

      // Update last active date
      await usersCollection.doc(user.uid).update({
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add user activity: $e');
    }
  }

  // Get user activities
  static Stream<List<UserActivity>> getUserActivities({int limit = 20}) {
    final user = auth.currentUser;
    if (user == null) return Stream.value([]);

    return _userActivitiesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserActivity.fromFirestore(doc);
          }).toList();
        });
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Delete user data from Firestore
      await usersCollection.doc(user.uid).delete();

      // Delete user activities
      final activitiesQuery = await _userActivitiesCollection
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in activitiesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }

  // Get user analytics
  static Future<UserAnalytics> getUserAnalytics() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user profile
      final profileDoc = await usersCollection.doc(user.uid).get();
      if (!profileDoc.exists) {
        // Return default analytics for new users
        return UserAnalytics(
          totalActivities: 0,
          weeklyActivities: 0,
          monthlyActivities: 0,
          currentStreak: 0,
          longestStreak: 0,
          totalTimeSpent: 0,
          averageScore: 0.0,
          level: 1,
          joinedDays: 0,
          lastActiveAgo: 0,
        );
      }

      final profile = UserProfile.fromFirestore(profileDoc);

      // Calculate analytics
      final now = DateTime.now();
      final thisWeek = now.subtract(const Duration(days: 7));
      final thisMonth = DateTime(now.year, now.month, 1);

      // Get recent activities
      final activitiesSnapshot = await _userActivitiesCollection
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thisMonth))
          .get();

      final weeklyActivities = activitiesSnapshot.docs.where((doc) {
        final timestamp =
            (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return timestamp.toDate().isAfter(thisWeek);
      }).length;

      final monthlyActivities = activitiesSnapshot.docs.length;

      return UserAnalytics(
        totalActivities: profile.stats.totalLessonsCompleted,
        weeklyActivities: weeklyActivities,
        monthlyActivities: monthlyActivities,
        currentStreak: profile.stats.currentStreak,
        longestStreak: profile.stats.longestStreak,
        totalTimeSpent: profile.stats.totalTimeSpent,
        averageScore: profile.stats.averageQuizScore,
        level: profile.stats.level,
        joinedDays: now.difference(profile.joinedDate).inDays,
        lastActiveAgo: now.difference(profile.lastActiveDate).inDays,
      );
    } catch (e) {
      // Return default analytics on error
      return UserAnalytics(
        totalActivities: 0,
        weeklyActivities: 0,
        monthlyActivities: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalTimeSpent: 0,
        averageScore: 0.0,
        level: 1,
        joinedDays: 0,
        lastActiveAgo: 0,
      );
    }
  }

  // Initialize new user profile
  static Future<void> initializeNewUserProfile() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final defaultProfile = UserProfile(
        uid: user.uid,
        displayName: user.displayName ?? 'User',
        email: user.email ?? '',
        photoURL: user.photoURL,
        joinedDate: DateTime.now(),
        lastActiveDate: DateTime.now(),
        preferences: UserPreferences(
          notificationSettings: NotificationSettings(),
          privacySettings: PrivacySettings(),
          learningPreferences: LearningPreferences(favoriteTopics: []),
          accessibilitySettings: AccessibilitySettings(),
        ),
        stats: UserStats(
          categoryProgress: {},
          activityHistory: [],
          lastLogin: DateTime.now(),
        ),
        interests: [],
        achievements: {},
        subscription: UserSubscription(features: []),
      );

      await createOrUpdateUserProfile(defaultProfile);

      // Add welcome activity
      await addUserActivity(
        UserActivity(
          type: ActivityType.accountCreated,
          title: 'Welcome to MIL Hub!',
          description: 'Your learning journey begins now',
          timestamp: DateTime.now(),
          metadata: {},
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize user profile: $e');
    }
  }

  // Search users (for social features)
  static Future<List<UserProfile>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get user by ID
  static Future<UserProfile?> getUserById(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update last active timestamp
  static Future<void> updateLastActive() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await usersCollection.doc(user.uid).update({
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail for this non-critical update
      print('Failed to update last active: $e');
    }
  }
}

// User Activity Model
class UserActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserActivity({
    this.id = '',
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.metadata,
  });

  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserActivity(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (t) => t.toString() == 'ActivityType.${data['type']}',
        orElse: () => ActivityType.other,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

enum ActivityType {
  lessonCompleted,
  quizPassed,
  achievementUnlocked,
  streakMaintained,
  profileUpdated,
  settingsChanged,
  accountCreated,
  loginActivity,
  communityPost,
  other,
}

// User Analytics Model
class UserAnalytics {
  final int totalActivities;
  final int weeklyActivities;
  final int monthlyActivities;
  final int currentStreak;
  final int longestStreak;
  final int totalTimeSpent;
  final double averageScore;
  final int level;
  final int joinedDays;
  final int lastActiveAgo;

  UserAnalytics({
    required this.totalActivities,
    required this.weeklyActivities,
    required this.monthlyActivities,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalTimeSpent,
    required this.averageScore,
    required this.level,
    required this.joinedDays,
    required this.lastActiveAgo,
  });
}
