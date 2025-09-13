import 'package:cloud_firestore/cloud_firestore.dart';

// Badge System
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final Map<String, dynamic> criteria;
  final int points;
  final DateTime? unlockedAt;
  final String? unlockedBy; // Achievement ID or action that unlocked it

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    required this.rarity,
    required this.criteria,
    this.points = 50,
    this.unlockedAt,
    this.unlockedBy,
  });

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? '',
      category: BadgeCategory.values.firstWhere(
        (c) => c.toString() == 'BadgeCategory.${data['category']}',
        orElse: () => BadgeCategory.learning,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (r) => r.toString() == 'BadgeRarity.${data['rarity']}',
        orElse: () => BadgeRarity.common,
      ),
      criteria: data['criteria'] ?? {},
      points: data['points'] ?? 50,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      unlockedBy: data['unlockedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'category': category.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'criteria': criteria,
      'points': points,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'unlockedBy': unlockedBy,
    };
  }

  bool get isUnlocked => unlockedAt != null;
}

enum BadgeCategory { learning, quiz, streak, social, special, milestone }

enum BadgeRarity { common, rare, epic, legendary }

// Leaderboard System
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int rank;
  final int points;
  final int lessonsCompleted;
  final int currentStreak;
  final Map<String, dynamic> stats;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.rank,
    required this.points,
    required this.lessonsCompleted,
    required this.currentStreak,
    required this.stats,
    required this.lastUpdated,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LeaderboardEntry(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      rank: data['rank'] ?? 0,
      points: data['points'] ?? 0,
      lessonsCompleted: data['lessonsCompleted'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      stats: data['stats'] ?? {},
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'rank': rank,
      'points': points,
      'lessonsCompleted': lessonsCompleted,
      'currentStreak': currentStreak,
      'stats': stats,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class Leaderboard {
  final String id;
  final String title;
  final LeaderboardType type;
  final LeaderboardPeriod period;
  final List<LeaderboardEntry> entries;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Leaderboard({
    required this.id,
    required this.title,
    required this.type,
    required this.period,
    required this.entries,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Leaderboard.fromFirestore(
    DocumentSnapshot doc,
    List<LeaderboardEntry> entries,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    return Leaderboard(
      id: doc.id,
      title: data['title'] ?? '',
      type: LeaderboardType.values.firstWhere(
        (t) => t.toString() == 'LeaderboardType.${data['type']}',
        orElse: () => LeaderboardType.points,
      ),
      period: LeaderboardPeriod.values.firstWhere(
        (p) => p.toString() == 'LeaderboardPeriod.${data['period']}',
        orElse: () => LeaderboardPeriod.weekly,
      ),
      entries: entries,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type.toString().split('.').last,
      'period': period.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }
}

enum LeaderboardType { points, lessons, streaks, quizScore, timeSpent }

enum LeaderboardPeriod { daily, weekly, monthly, allTime }

// Enhanced Streak System
class StreakMilestone {
  final int days;
  final String title;
  final String description;
  final String badgeId;
  final int bonusPoints;

  StreakMilestone({
    required this.days,
    required this.title,
    required this.description,
    required this.badgeId,
    required this.bonusPoints,
  });

  factory StreakMilestone.fromMap(Map<String, dynamic> data) {
    return StreakMilestone(
      days: data['days'] ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      badgeId: data['badgeId'] ?? '',
      bonusPoints: data['bonusPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'title': title,
      'description': description,
      'badgeId': badgeId,
      'bonusPoints': bonusPoints,
    };
  }
}

class EnhancedStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final DateTime streakStartDate;
  final int totalActiveDays;
  final List<DateTime> activityDates;
  final Map<String, int>
  streaksByCategory; // e.g., {'lessons': 5, 'quizzes': 3}
  final List<StreakMilestone> achievedMilestones;
  final int freezeCount; // Number of streak freezes available
  final DateTime? lastFreezeUsed;

  EnhancedStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    required this.streakStartDate,
    this.totalActiveDays = 0,
    required this.activityDates,
    required this.streaksByCategory,
    required this.achievedMilestones,
    this.freezeCount = 0,
    this.lastFreezeUsed,
  });

  factory EnhancedStreak.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EnhancedStreak(
      userId: data['userId'] ?? '',
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActivityDate: data['lastActivityDate'] != null
          ? (data['lastActivityDate'] as Timestamp).toDate()
          : null,
      streakStartDate: (data['streakStartDate'] as Timestamp).toDate(),
      totalActiveDays: data['totalActiveDays'] ?? 0,
      activityDates:
          (data['activityDates'] as List<dynamic>?)
              ?.map((date) => (date as Timestamp).toDate())
              .toList() ??
          [],
      streaksByCategory: Map<String, int>.from(data['streaksByCategory'] ?? {}),
      achievedMilestones:
          (data['achievedMilestones'] as List<dynamic>?)
              ?.map((milestone) => StreakMilestone.fromMap(milestone))
              .toList() ??
          [],
      freezeCount: data['freezeCount'] ?? 0,
      lastFreezeUsed: data['lastFreezeUsed'] != null
          ? (data['lastFreezeUsed'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'streakStartDate': Timestamp.fromDate(streakStartDate),
      'totalActiveDays': totalActiveDays,
      'activityDates': activityDates
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      'streaksByCategory': streaksByCategory,
      'achievedMilestones': achievedMilestones
          .map((milestone) => milestone.toMap())
          .toList(),
      'freezeCount': freezeCount,
      'lastFreezeUsed': lastFreezeUsed != null
          ? Timestamp.fromDate(lastFreezeUsed!)
          : null,
    };
  }

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final today = DateTime.now();
    final lastActivity = lastActivityDate!;
    return today.year == lastActivity.year &&
        today.month == lastActivity.month &&
        today.day == lastActivity.day;
  }

  bool get canUseFreeze {
    return freezeCount > 0 &&
        (lastFreezeUsed == null ||
            DateTime.now().difference(lastFreezeUsed!).inDays >= 7);
  }

  bool get isStreakBroken {
    if (lastActivityDate == null) return true;
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastActivityDate!).inDays;
    return daysSinceLastActivity > 1 && !canUseFreeze;
  }

  int get daysUntilNextMilestone {
    final availableMilestones = [3, 7, 14, 30, 60, 100, 365];
    final nextMilestone = availableMilestones.firstWhere(
      (milestone) => milestone > currentStreak,
      orElse: () => -1,
    );
    return nextMilestone > 0 ? nextMilestone - currentStreak : -1;
  }
}

// XP and Level System
class XPSystem {
  static const int baseXPPerLevel = 1000;
  static const double multiplier = 1.2;

  static int getXPForLevel(int level) {
    if (level <= 1) return 0;
    double total = 0;
    for (int i = 2; i <= level; i++) {
      total += baseXPPerLevel * (multiplier * (i - 1));
    }
    return total.round();
  }

  static int getLevelFromXP(int xp) {
    int level = 1;
    int requiredXP = 0;

    while (xp >= requiredXP) {
      level++;
      requiredXP += (baseXPPerLevel * (multiplier * (level - 1))).round();
    }

    return level - 1;
  }

  static int getXPForNextLevel(int currentLevel) {
    return (baseXPPerLevel * (multiplier * currentLevel)).round();
  }

  static double getProgressToNextLevel(int xp, int currentLevel) {
    final currentLevelXP = getXPForLevel(currentLevel);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    final progressXP = xp - currentLevelXP;
    final requiredXP = nextLevelXP - currentLevelXP;

    return progressXP / requiredXP;
  }
}

// Gamification Event
class GamificationEvent {
  final String id;
  final String userId;
  final GamificationEventType type;
  final Map<String, dynamic> data;
  final int xpGained;
  final int pointsGained;
  final List<String> badgesUnlocked;
  final List<String> achievementsUnlocked;
  final DateTime timestamp;

  GamificationEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    this.xpGained = 0,
    this.pointsGained = 0,
    required this.badgesUnlocked,
    required this.achievementsUnlocked,
    required this.timestamp,
  });

  factory GamificationEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GamificationEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: GamificationEventType.values.firstWhere(
        (t) => t.toString() == 'GamificationEventType.${data['type']}',
        orElse: () => GamificationEventType.lessonCompleted,
      ),
      data: data['data'] ?? {},
      xpGained: data['xpGained'] ?? 0,
      pointsGained: data['pointsGained'] ?? 0,
      badgesUnlocked: List<String>.from(data['badgesUnlocked'] ?? []),
      achievementsUnlocked: List<String>.from(
        data['achievementsUnlocked'] ?? [],
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'data': data,
      'xpGained': xpGained,
      'pointsGained': pointsGained,
      'badgesUnlocked': badgesUnlocked,
      'achievementsUnlocked': achievementsUnlocked,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

enum GamificationEventType {
  lessonCompleted,
  quizPassed,
  streakMaintained,
  badgeEarned,
  achievementUnlocked,
  levelUp,
  milestoneReached,
}
