import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/gamification_model.dart';
import '../models/user_progress_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _badgesCollection => _firestore.collection('badges');
  CollectionReference get _userBadgesCollection =>
      _firestore.collection('userBadges');
  CollectionReference get _leaderboardsCollection =>
      _firestore.collection('leaderboards');
  CollectionReference get _leaderboardEntriesCollection =>
      _firestore.collection('leaderboardEntries');
  CollectionReference get _streaksCollection =>
      _firestore.collection('enhancedStreaks');
  CollectionReference get _gamificationEventsCollection =>
      _firestore.collection('gamificationEvents');

  // Badge Management
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final snapshot = await _userBadgesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final badgeIds = snapshot.docs
          .map((doc) => doc['badgeId'] as String)
          .toList();

      if (badgeIds.isEmpty) return [];

      final badgesSnapshot = await _badgesCollection
          .where(FieldPath.documentId, whereIn: badgeIds)
          .get();

      return badgesSnapshot.docs
          .map((doc) => Badge.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  Future<List<Badge>> getAllBadges() async {
    try {
      final snapshot = await _badgesCollection.orderBy('category').get();
      return snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all badges: $e');
      return _generateDefaultBadges();
    }
  }

  Future<void> checkAndUnlockBadges(
    String userId,
    GamificationEventType eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final userStats = await _getUserStats(userId);
      final userBadges = await getUserBadges(userId);
      final allBadges = await getAllBadges();

      final unlockedBadgeIds = userBadges.map((b) => b.id).toSet();
      final eligibleBadges = allBadges.where(
        (badge) => !unlockedBadgeIds.contains(badge.id),
      );

      for (final badge in eligibleBadges) {
        if (_checkBadgeCriteria(badge, userStats, eventType, eventData)) {
          await _unlockBadge(userId, badge.id);
          await _recordGamificationEvent(
            userId: userId,
            type: GamificationEventType.badgeEarned,
            data: {'badgeId': badge.id, 'badgeName': badge.name},
            pointsGained: badge.points,
            badgesUnlocked: [badge.id],
          );
        }
      }
    } catch (e) {
      print('Error checking badges: $e');
    }
  }

  bool _checkBadgeCriteria(
    Badge badge,
    UserLearningStats stats,
    GamificationEventType eventType,
    Map<String, dynamic> eventData,
  ) {
    switch (badge.category) {
      case BadgeCategory.learning:
        final requiredLessons = badge.criteria['lessonsCompleted'] as int? ?? 0;
        return stats.totalLessonsCompleted >= requiredLessons;

      case BadgeCategory.quiz:
        final requiredQuizzes = badge.criteria['quizzesPassed'] as int? ?? 0;
        final requiredScore = badge.criteria['averageScore'] as double? ?? 0.0;
        return stats.totalQuizzesTaken >= requiredQuizzes &&
            stats.averageQuizScore >= requiredScore;

      case BadgeCategory.streak:
        final requiredStreak = badge.criteria['streakDays'] as int? ?? 0;
        return (stats.streak?.currentStreak ?? 0) >= requiredStreak;

      case BadgeCategory.milestone:
        final requiredPoints = badge.criteria['totalPoints'] as int? ?? 0;
        return stats.totalAchievementPoints >= requiredPoints;

      default:
        return false;
    }
  }

  Future<void> _unlockBadge(String userId, String badgeId) async {
    await _userBadgesCollection.add({
      'userId': userId,
      'badgeId': badgeId,
      'unlockedAt': Timestamp.now(),
    });
  }

  // Leaderboard Management
  Future<Leaderboard> getLeaderboard(
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    try {
      final leaderboardId =
          '${type.toString().split('.').last}_${period.toString().split('.').last}';

      // Get leaderboard metadata
      final leaderboardDoc = await _leaderboardsCollection
          .doc(leaderboardId)
          .get();

      if (!leaderboardDoc.exists) {
        return _createDefaultLeaderboard(type, period);
      }

      // Get leaderboard entries
      final entriesSnapshot = await _leaderboardEntriesCollection
          .where('leaderboardId', isEqualTo: leaderboardId)
          .orderBy('rank')
          .limit(100)
          .get();

      final entries = entriesSnapshot.docs
          .map((doc) => LeaderboardEntry.fromFirestore(doc))
          .toList();

      return Leaderboard.fromFirestore(leaderboardDoc, entries);
    } catch (e) {
      print('Error getting leaderboard: $e');
      return _createDefaultLeaderboard(type, period);
    }
  }

  Future<int> getUserRank(
    String userId,
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    try {
      final leaderboardId =
          '${type.toString().split('.').last}_${period.toString().split('.').last}';

      final entrySnapshot = await _leaderboardEntriesCollection
          .where('leaderboardId', isEqualTo: leaderboardId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (entrySnapshot.docs.isNotEmpty) {
        return entrySnapshot.docs.first['rank'] as int;
      }

      return -1; // Not ranked
    } catch (e) {
      print('Error getting user rank: $e');
      return -1;
    }
  }

  Future<void> updateLeaderboard(String userId, UserLearningStats stats) async {
    try {
      final leaderboardTypes = [
        LeaderboardType.points,
        LeaderboardType.lessons,
        LeaderboardType.streaks,
      ];

      final periods = [
        LeaderboardPeriod.weekly,
        LeaderboardPeriod.monthly,
        LeaderboardPeriod.allTime,
      ];

      for (final type in leaderboardTypes) {
        for (final period in periods) {
          await _updateUserLeaderboardEntry(userId, stats, type, period);
        }
      }
    } catch (e) {
      print('Error updating leaderboard: $e');
    }
  }

  Future<void> _updateUserLeaderboardEntry(
    String userId,
    UserLearningStats stats,
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    final leaderboardId =
        '${type.toString().split('.').last}_${period.toString().split('.').last}';

    int points = 0;
    switch (type) {
      case LeaderboardType.points:
        points = stats.totalAchievementPoints;
        break;
      case LeaderboardType.lessons:
        points = stats.totalLessonsCompleted;
        break;
      case LeaderboardType.streaks:
        points = stats.streak?.currentStreak ?? 0;
        break;
      default:
        points = stats.totalAchievementPoints;
    }

    // Update or create user entry
    await _leaderboardEntriesCollection.doc('${leaderboardId}_$userId').set({
      'leaderboardId': leaderboardId,
      'userId': userId,
      'displayName': 'User $userId', // In real app, get from user profile
      'points': points,
      'lessonsCompleted': stats.totalLessonsCompleted,
      'currentStreak': stats.streak?.currentStreak ?? 0,
      'stats': {
        'totalTimeSpent': stats.totalTimeSpent,
        'averageQuizScore': stats.averageQuizScore,
      },
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));

    // Update ranks
    await _updateRanks(leaderboardId);
  }

  Future<void> _updateRanks(String leaderboardId) async {
    final entriesSnapshot = await _leaderboardEntriesCollection
        .where('leaderboardId', isEqualTo: leaderboardId)
        .orderBy('points', descending: true)
        .get();

    final batch = _firestore.batch();

    for (int i = 0; i < entriesSnapshot.docs.length; i++) {
      final doc = entriesSnapshot.docs[i];
      batch.update(doc.reference, {'rank': i + 1});
    }

    await batch.commit();
  }

  // Enhanced Streak Management
  Future<EnhancedStreak> getEnhancedStreak(String userId) async {
    try {
      final doc = await _streaksCollection.doc(userId).get();

      if (doc.exists) {
        return EnhancedStreak.fromFirestore(doc);
      } else {
        // Create new streak
        final newStreak = EnhancedStreak(
          userId: userId,
          streakStartDate: DateTime.now(),
          activityDates: [],
          streaksByCategory: {},
          achievedMilestones: [],
        );

        await _streaksCollection.doc(userId).set(newStreak.toFirestore());
        return newStreak;
      }
    } catch (e) {
      print('Error getting enhanced streak: $e');
      return EnhancedStreak(
        userId: userId,
        streakStartDate: DateTime.now(),
        activityDates: [],
        streaksByCategory: {},
        achievedMilestones: [],
      );
    }
  }

  Future<void> updateStreak(String userId, String category) async {
    try {
      final streak = await getEnhancedStreak(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already active today
      final isActiveToday = streak.activityDates.any((date) {
        final activityDay = DateTime(date.year, date.month, date.day);
        return activityDay.isAtSameMomentAs(today);
      });

      if (isActiveToday) return; // Already counted for today

      // Update activity
      final updatedActivityDates = [...streak.activityDates, now];
      final updatedStreaksByCategory = Map<String, int>.from(
        streak.streaksByCategory,
      );
      updatedStreaksByCategory[category] =
          (updatedStreaksByCategory[category] ?? 0) + 1;

      // Calculate new streak
      int newCurrentStreak = streak.currentStreak;
      final yesterday = today.subtract(const Duration(days: 1));

      final wasActiveYesterday = streak.activityDates.any((date) {
        final activityDay = DateTime(date.year, date.month, date.day);
        return activityDay.isAtSameMomentAs(yesterday);
      });

      if (wasActiveYesterday || streak.currentStreak == 0) {
        newCurrentStreak = streak.currentStreak + 1;
      } else {
        newCurrentStreak = 1; // Reset streak
      }

      final newLongestStreak = math.max(streak.longestStreak, newCurrentStreak);

      // Check for milestones
      final newMilestones = <StreakMilestone>[...streak.achievedMilestones];
      await _checkStreakMilestones(userId, newCurrentStreak, newMilestones);

      // Update streak
      final updatedStreak = EnhancedStreak(
        userId: userId,
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastActivityDate: now,
        streakStartDate: streak.streakStartDate,
        totalActiveDays: streak.totalActiveDays + 1,
        activityDates: updatedActivityDates,
        streaksByCategory: updatedStreaksByCategory,
        achievedMilestones: newMilestones,
        freezeCount: streak.freezeCount,
        lastFreezeUsed: streak.lastFreezeUsed,
      );

      await _streaksCollection.doc(userId).set(updatedStreak.toFirestore());

      // Record event
      await _recordGamificationEvent(
        userId: userId,
        type: GamificationEventType.streakMaintained,
        data: {'currentStreak': newCurrentStreak, 'category': category},
        xpGained: newCurrentStreak * 10,
        pointsGained: newCurrentStreak * 5,
      );
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<void> _checkStreakMilestones(
    String userId,
    int currentStreak,
    List<StreakMilestone> achievedMilestones,
  ) async {
    final milestones = [
      StreakMilestone(
        days: 3,
        title: 'Getting Started',
        description: '3-day learning streak',
        badgeId: 'streak_3_days',
        bonusPoints: 50,
      ),
      StreakMilestone(
        days: 7,
        title: 'Week Warrior',
        description: '7-day learning streak',
        badgeId: 'streak_week',
        bonusPoints: 100,
      ),
      StreakMilestone(
        days: 30,
        title: 'Month Master',
        description: '30-day learning streak',
        badgeId: 'streak_month',
        bonusPoints: 500,
      ),
      StreakMilestone(
        days: 100,
        title: 'Century Scholar',
        description: '100-day learning streak',
        badgeId: 'streak_century',
        bonusPoints: 2000,
      ),
    ];

    final achievedDays = achievedMilestones.map((m) => m.days).toSet();

    for (final milestone in milestones) {
      if (currentStreak >= milestone.days &&
          !achievedDays.contains(milestone.days)) {
        achievedMilestones.add(milestone);

        await _recordGamificationEvent(
          userId: userId,
          type: GamificationEventType.milestoneReached,
          data: {
            'milestoneTitle': milestone.title,
            'streakDays': milestone.days,
          },
          pointsGained: milestone.bonusPoints,
        );
      }
    }
  }

  Future<bool> useStreakFreeze(String userId) async {
    try {
      final streak = await getEnhancedStreak(userId);

      if (!streak.canUseFreeze) return false;

      final updatedStreak = EnhancedStreak(
        userId: userId,
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        lastActivityDate: DateTime.now(), // Extend streak
        streakStartDate: streak.streakStartDate,
        totalActiveDays: streak.totalActiveDays,
        activityDates: streak.activityDates,
        streaksByCategory: streak.streaksByCategory,
        achievedMilestones: streak.achievedMilestones,
        freezeCount: streak.freezeCount - 1,
        lastFreezeUsed: DateTime.now(),
      );

      await _streaksCollection.doc(userId).set(updatedStreak.toFirestore());
      return true;
    } catch (e) {
      print('Error using streak freeze: $e');
      return false;
    }
  }

  // XP and Level Management
  Future<void> addXP(String userId, int xp, String reason) async {
    try {
      await _recordGamificationEvent(
        userId: userId,
        type: GamificationEventType.lessonCompleted,
        data: {'reason': reason},
        xpGained: xp,
      );
    } catch (e) {
      print('Error adding XP: $e');
    }
  }

  // Event Recording
  Future<void> _recordGamificationEvent({
    required String userId,
    required GamificationEventType type,
    required Map<String, dynamic> data,
    int xpGained = 0,
    int pointsGained = 0,
    List<String> badgesUnlocked = const [],
    List<String> achievementsUnlocked = const [],
  }) async {
    try {
      final event = GamificationEvent(
        id: '',
        userId: userId,
        type: type,
        data: data,
        xpGained: xpGained,
        pointsGained: pointsGained,
        badgesUnlocked: badgesUnlocked,
        achievementsUnlocked: achievementsUnlocked,
        timestamp: DateTime.now(),
      );

      await _gamificationEventsCollection.add(event.toFirestore());
    } catch (e) {
      print('Error recording gamification event: $e');
    }
  }

  // Helper Methods
  Future<UserLearningStats> _getUserStats(String userId) async {
    // In a real app, this would fetch from the user stats collection
    // For now, return mock data
    final sampleStreak = LearningStreak(
      userId: userId,
      currentStreak: 5,
      longestStreak: 10,
      lastActivityDate: DateTime.now(),
      streakStartDate: DateTime.now().subtract(Duration(days: 5)),
      totalActiveDays: 15,
    );

    return UserLearningStats(
      userId: userId,
      totalLessonsCompleted: 10,
      totalQuizzesTaken: 5,
      averageQuizScore: 0.85,
      totalTimeSpent: 3600,
      totalAchievementPoints: 500,
      streak: sampleStreak,
      achievementIds: [],
      subjectProgress: {},
      lastUpdated: DateTime.now(),
    );
  }

  Leaderboard _createDefaultLeaderboard(
    LeaderboardType type,
    LeaderboardPeriod period,
  ) {
    return Leaderboard(
      id: '${type.toString().split('.').last}_${period.toString().split('.').last}',
      title:
          '${period.toString().split('.').last.toUpperCase()} ${type.toString().split('.').last.toUpperCase()}',
      type: type,
      period: period,
      entries: _generateSampleLeaderboardEntries(),
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
    );
  }

  List<LeaderboardEntry> _generateSampleLeaderboardEntries() {
    final names = [
      'Alice',
      'Bob',
      'Charlie',
      'Diana',
      'Eve',
      'Frank',
      'Grace',
      'Henry',
    ];
    final entries = <LeaderboardEntry>[];

    for (int i = 0; i < names.length; i++) {
      entries.add(
        LeaderboardEntry(
          userId: 'user_${i + 1}',
          displayName: names[i],
          rank: i + 1,
          points: 2000 - (i * 200),
          lessonsCompleted: 25 - (i * 2),
          currentStreak: 15 - i,
          stats: {},
          lastUpdated: DateTime.now(),
        ),
      );
    }

    return entries;
  }

  List<Badge> _generateDefaultBadges() {
    return [
      Badge(
        id: 'first_lesson',
        name: 'First Steps',
        description: 'Complete your first lesson',
        iconName: 'school',
        category: BadgeCategory.learning,
        rarity: BadgeRarity.common,
        criteria: {'lessonsCompleted': 1},
        points: 50,
      ),
      Badge(
        id: 'quiz_master',
        name: 'Quiz Master',
        description: 'Score 90% or higher on 5 quizzes',
        iconName: 'quiz',
        category: BadgeCategory.quiz,
        rarity: BadgeRarity.rare,
        criteria: {'quizzesPassed': 5, 'averageScore': 0.9},
        points: 200,
      ),
      Badge(
        id: 'streak_week',
        name: 'Week Warrior',
        description: 'Maintain a 7-day learning streak',
        iconName: 'local_fire_department',
        category: BadgeCategory.streak,
        rarity: BadgeRarity.epic,
        criteria: {'streakDays': 7},
        points: 300,
      ),
    ];
  }
}
