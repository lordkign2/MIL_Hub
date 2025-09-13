import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_lesson_model.dart';
import '../models/user_progress_model.dart';
import 'dart:math' as math;

class LearningService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _lessonsCollection = 'lessons';
  static const String _userProgressCollection = 'userLessonProgress';
  static const String _quizAttemptsCollection = 'quizAttempts';
  static const String _achievementsCollection = 'achievements';
  static const String _userStatsCollection = 'userLearningStats';
  static const String _streaksCollection = 'learningStreaks';

  // Lessons
  static Stream<List<EnhancedLesson>> getLessonsStream({
    LessonDifficulty? difficulty,
    LessonType? type,
    List<String>? tags,
    bool? isFeatured,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection(_lessonsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('order');

    if (difficulty != null) {
      query = query.where(
        'difficulty',
        isEqualTo: difficulty.toString().split('.').last,
      );
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }

    if (isFeatured != null) {
      query = query.where('isFeatured', isEqualTo: isFeatured);
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => EnhancedLesson.fromFirestore(doc))
          .toList(),
    );
  }

  static Future<EnhancedLesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore
          .collection(_lessonsCollection)
          .doc(lessonId)
          .get();
      if (doc.exists) {
        return EnhancedLesson.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lesson: $e');
    }
  }

  static Stream<List<EnhancedLesson>> getFeaturedLessons() {
    return _firestore
        .collection(_lessonsCollection)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('order')
        .limit(5)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EnhancedLesson.fromFirestore(doc))
              .toList(),
        );
  }

  static Stream<List<EnhancedLesson>> getRecommendedLessons() {
    // This would use AI/ML in production. For now, return popular lessons.
    return _firestore
        .collection(_lessonsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('analytics.viewCount', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EnhancedLesson.fromFirestore(doc))
              .toList(),
        );
  }

  static Future<List<EnhancedLesson>> searchLessons(
    String query, {
    int limit = 20,
  }) async {
    // Simple text search - in production, use Algolia or similar
    final snapshot = await _firestore
        .collection(_lessonsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    final lessons = snapshot.docs
        .map((doc) => EnhancedLesson.fromFirestore(doc))
        .where(
          (lesson) =>
              lesson.title.toLowerCase().contains(query.toLowerCase()) ||
              lesson.description.toLowerCase().contains(query.toLowerCase()) ||
              lesson.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .take(limit)
        .toList();

    return lessons;
  }

  // User Progress
  static Stream<UserLessonProgress?> getUserLessonProgress(String lessonId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return UserLessonProgress.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  static Stream<List<UserLessonProgress>> getUserProgressStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserLessonProgress.fromFirestore(doc))
              .toList(),
        );
  }

  static Future<void> updateLessonProgress({
    required String lessonId,
    required double progress,
    LessonStatus? status,
    int? additionalTimeSpent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection(_userProgressCollection)
        .doc('${user.uid}_$lessonId');

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final now = DateTime.now();

      if (doc.exists) {
        final existingProgress = UserLessonProgress.fromFirestore(doc);
        final updatedProgress = existingProgress.copyWith(
          progress: math.max(existingProgress.progress, progress),
          status: status ?? existingProgress.status,
          timeSpent: existingProgress.timeSpent + (additionalTimeSpent ?? 0),
          lastAccessedAt: now,
          completedAt: status == LessonStatus.completed
              ? now
              : existingProgress.completedAt,
        );
        transaction.update(docRef, updatedProgress.toFirestore());
      } else {
        final newProgress = UserLessonProgress(
          userId: user.uid,
          lessonId: lessonId,
          progress: progress,
          status: status ?? LessonStatus.inProgress,
          timeSpent: additionalTimeSpent ?? 0,
          startedAt: now,
          lastAccessedAt: now,
          completedAt: status == LessonStatus.completed ? now : null,
        );
        transaction.set(docRef, newProgress.toFirestore());
      }
    });

    // Update user stats
    await _updateUserStats();
  }

  static Future<void> toggleBookmark(String lessonId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection(_userProgressCollection)
        .doc('${user.uid}_$lessonId');

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final now = DateTime.now();

      if (doc.exists) {
        final progress = UserLessonProgress.fromFirestore(doc);
        transaction.update(docRef, {
          'isBookmarked': !progress.isBookmarked,
          'lastAccessedAt': Timestamp.fromDate(now),
        });
      } else {
        final newProgress = UserLessonProgress(
          userId: user.uid,
          lessonId: lessonId,
          isBookmarked: true,
          lastAccessedAt: now,
        );
        transaction.set(docRef, newProgress.toFirestore());
      }
    });
  }

  static Stream<List<UserLessonProgress>> getBookmarkedLessons() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .where('isBookmarked', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserLessonProgress.fromFirestore(doc))
              .toList(),
        );
  }

  // Quiz Management
  static Future<String> submitQuizAttempt({
    required String lessonId,
    required List<QuestionAttempt> questionAttempts,
    required int timeSpent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final correctAnswers = questionAttempts.where((q) => q.isCorrect).length;
    final score = correctAnswers / questionAttempts.length;
    final now = DateTime.now();

    final quizAttempt = QuizAttempt(
      id: '', // Will be set by Firestore
      lessonId: lessonId,
      userId: user.uid,
      score: score,
      totalQuestions: questionAttempts.length,
      correctAnswers: correctAnswers,
      timeSpent: timeSpent,
      startedAt: now.subtract(Duration(seconds: timeSpent)),
      completedAt: now,
      questionAttempts: questionAttempts,
      analytics: {
        'averageTimePerQuestion': timeSpent / questionAttempts.length,
        'difficultyRating': _calculateDifficultyRating(questionAttempts),
      },
    );

    // Save quiz attempt
    final docRef = await _firestore
        .collection(_quizAttemptsCollection)
        .add(quizAttempt.toMap());

    // Update lesson progress
    await updateLessonProgress(
      lessonId: lessonId,
      progress: 1.0,
      status: score >= 0.7 ? LessonStatus.completed : LessonStatus.inProgress,
      additionalTimeSpent: timeSpent,
    );

    // Update user lesson progress with quiz attempt
    final progressDocRef = _firestore
        .collection(_userProgressCollection)
        .doc('${user.uid}_$lessonId');

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(progressDocRef);
      if (doc.exists) {
        final progress = UserLessonProgress.fromFirestore(doc);
        final updatedAttempts = List<QuizAttempt>.from(progress.quizAttempts);
        updatedAttempts.add(quizAttempt.copyWith(id: docRef.id));

        transaction.update(progressDocRef, {
          'quizAttempts': updatedAttempts.map((q) => q.toMap()).toList(),
        });
      }
    });

    // Achievement System
    await _checkAndUnlockAchievements(
      score,
      correctAnswers,
      questionAttempts.length,
    );

    // Update learning streak
    await _updateLearningStreak();

    return docRef.id;
  }

  static double _calculateDifficultyRating(List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    final totalTime = attempts.fold(
      0,
      (sum, attempt) => sum + attempt.timeSpent,
    );
    final averageTime = totalTime / attempts.length;
    final correctRate =
        attempts.where((a) => a.isCorrect).length / attempts.length;

    // Simple difficulty calculation based on time and accuracy
    return (averageTime / 30.0) * (1.0 - correctRate) * 5.0;
  }

  static Future<void> _checkAndUnlockAchievements(
    double score,
    int correctAnswers,
    int totalQuestions,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userStats = await getUserStats().first;
    if (userStats == null) return;

    // Define achievement criteria
    final achievementChecks = [
      {
        'id': 'first_lesson',
        'title': 'First Steps',
        'description': 'Complete your first lesson',
        'type': AchievementType.completion,
        'iconName': 'first_lesson',
        'points': 10,
        'rarity': 'common',
        'criteria': () => userStats.totalLessonsCompleted >= 1,
      },
      {
        'id': 'quiz_master',
        'title': 'Quiz Master',
        'description': 'Take 10 quizzes',
        'type': AchievementType.mastery,
        'iconName': 'quiz_master',
        'points': 25,
        'rarity': 'rare',
        'criteria': () => userStats.totalQuizzesTaken >= 10,
      },
      {
        'id': 'perfect_score',
        'title': 'Perfect Score',
        'description': 'Get 100% on a quiz',
        'type': AchievementType.perfectionist,
        'iconName': 'perfect_score',
        'points': 20,
        'rarity': 'rare',
        'criteria': () => score >= 1.0,
      },
      {
        'id': 'speed_learner',
        'title': 'Speed Learner',
        'description': 'Complete 5 lessons in one day',
        'type': AchievementType.speedster,
        'iconName': 'speed_learner',
        'points': 30,
        'rarity': 'epic',
        'criteria': () async => await _checkDailyLessons(5),
      },
      {
        'id': 'dedicated_learner',
        'title': 'Dedicated Learner',
        'description': 'Complete 50 lessons',
        'type': AchievementType.completion,
        'iconName': 'dedicated_learner',
        'points': 100,
        'rarity': 'legendary',
        'criteria': () => userStats.totalLessonsCompleted >= 50,
      },
      {
        'id': 'streak_keeper',
        'title': 'Streak Keeper',
        'description': 'Maintain a 7-day learning streak',
        'type': AchievementType.streak,
        'iconName': 'streak_keeper',
        'points': 50,
        'rarity': 'epic',
        'criteria': () => (userStats.streak?.currentStreak ?? 0) >= 7,
      },
    ];

    // Check each achievement
    for (final achievementData in achievementChecks) {
      final criteria = achievementData['criteria'] as dynamic Function();
      bool shouldUnlock = false;

      if (criteria is Future<bool> Function()) {
        shouldUnlock = await criteria();
      } else if (criteria is bool Function()) {
        shouldUnlock = criteria();
      }

      if (shouldUnlock) {
        await _unlockAchievement(
          achievementData['id'] as String,
          achievementData['title'] as String,
          achievementData['description'] as String,
          achievementData['type'] as AchievementType,
          achievementData['iconName'] as String,
          achievementData['points'] as int,
          achievementData['rarity'] as String,
        );
      }
    }
  }

  static Future<bool> _checkDailyLessons(int target) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.length >= target;
  }

  static Future<void> _unlockAchievement(
    String id,
    String title,
    String description,
    AchievementType type,
    String iconName,
    int points,
    String rarity,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if already unlocked
    final existingDoc = await _firestore
        .collection(_achievementsCollection)
        .doc('${user.uid}_$id')
        .get();

    if (existingDoc.exists) {
      final achievement = Achievement.fromFirestore(existingDoc);
      if (achievement.unlockedAt != null) {
        return; // Already unlocked
      }
    }

    // Unlock achievement
    final achievement = Achievement(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      type: type,
      criteria: {},
      unlockedAt: DateTime.now(),
      points: points,
      rarity: rarity,
    );

    await _firestore
        .collection(_achievementsCollection)
        .doc('${user.uid}_$id')
        .set(achievement.toFirestore(), SetOptions(merge: true));

    // Update user stats
    await _updateUserStats();
  }

  // Achievements
  static Stream<List<Achievement>> getUserAchievements() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_achievementsCollection)
        .where('id', isGreaterThanOrEqualTo: '${user.uid}_')
        .where('id', isLessThan: '${user.uid}_\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Achievement.fromFirestore(doc))
              .toList();
        });
  }

  static Future<List<Achievement>> getAllPossibleAchievements() async {
    // Return all possible achievements for the user
    // This includes both unlocked and locked achievements
    final user = _auth.currentUser;
    if (user == null) return [];

    final achievementTemplates = [
      {
        'id': 'first_lesson',
        'title': 'First Steps',
        'description': 'Complete your first lesson',
        'type': AchievementType.completion,
        'iconName': 'first_lesson',
        'points': 10,
        'rarity': 'common',
      },
      {
        'id': 'quiz_master',
        'title': 'Quiz Master',
        'description': 'Take 10 quizzes',
        'type': AchievementType.mastery,
        'iconName': 'quiz_master',
        'points': 25,
        'rarity': 'rare',
      },
      {
        'id': 'perfect_score',
        'title': 'Perfect Score',
        'description': 'Get 100% on a quiz',
        'type': AchievementType.perfectionist,
        'iconName': 'perfect_score',
        'points': 20,
        'rarity': 'rare',
      },
      {
        'id': 'speed_learner',
        'title': 'Speed Learner',
        'description': 'Complete 5 lessons in one day',
        'type': AchievementType.speedster,
        'iconName': 'speed_learner',
        'points': 30,
        'rarity': 'epic',
      },
      {
        'id': 'dedicated_learner',
        'title': 'Dedicated Learner',
        'description': 'Complete 50 lessons',
        'type': AchievementType.completion,
        'iconName': 'dedicated_learner',
        'points': 100,
        'rarity': 'legendary',
      },
      {
        'id': 'streak_keeper',
        'title': 'Streak Keeper',
        'description': 'Maintain a 7-day learning streak',
        'type': AchievementType.streak,
        'iconName': 'streak_keeper',
        'points': 50,
        'rarity': 'epic',
      },
    ];

    // Get user's unlocked achievements
    final unlockedSnapshot = await _firestore
        .collection(_achievementsCollection)
        .where('id', isGreaterThanOrEqualTo: '${user.uid}_')
        .where('id', isLessThan: '${user.uid}_\uf8ff')
        .get();

    final unlockedMap = <String, Achievement>{};
    for (final doc in unlockedSnapshot.docs) {
      final achievement = Achievement.fromFirestore(doc);
      final achievementId = achievement.id.split('_').last;
      unlockedMap[achievementId] = achievement;
    }

    // Create complete list with unlocked status
    final allAchievements = <Achievement>[];
    for (final template in achievementTemplates) {
      final id = template['id'] as String;
      if (unlockedMap.containsKey(id)) {
        allAchievements.add(unlockedMap[id]!);
      } else {
        allAchievements.add(
          Achievement(
            id: id,
            title: template['title'] as String,
            description: template['description'] as String,
            iconName: template['iconName'] as String,
            type: template['type'] as AchievementType,
            criteria: {},
            unlockedAt: null, // Locked
            points: template['points'] as int,
            rarity: template['rarity'] as String,
          ),
        );
      }
    }

    return allAchievements;
  }

  // Progress Analytics
  static Future<Map<String, dynamic>> getDetailedProgress() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    // Get all user progress
    final progressSnapshot = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    final progressList = progressSnapshot.docs
        .map((doc) => UserLessonProgress.fromFirestore(doc))
        .toList();

    // Calculate detailed analytics
    final now = DateTime.now();
    final thisWeek = now.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);

    final weeklyProgress = progressList
        .where((p) => p.completedAt != null && p.completedAt!.isAfter(thisWeek))
        .length;

    final monthlyProgress = progressList
        .where(
          (p) => p.completedAt != null && p.completedAt!.isAfter(thisMonth),
        )
        .length;

    final averageScore = progressList.isNotEmpty
        ? progressList
                  .where((p) => p.quizAttempts.isNotEmpty)
                  .map((p) => p.bestQuizScore)
                  .fold(0.0, (sum, score) => sum + score) /
              progressList.where((p) => p.quizAttempts.isNotEmpty).length
        : 0.0;

    final totalTimeSpent = progressList.fold(0, (sum, p) => sum + p.timeSpent);

    // Get streak info
    final streakDoc = await _firestore
        .collection(_streaksCollection)
        .doc(user.uid)
        .get();

    LearningStreak? streak;
    if (streakDoc.exists) {
      streak = LearningStreak.fromFirestore(streakDoc);
    }

    // Get achievements
    final achievements = await getAllPossibleAchievements();
    final unlockedAchievements = achievements
        .where((a) => a.unlockedAt != null)
        .length;
    final totalPoints = achievements
        .where((a) => a.unlockedAt != null)
        .fold(0, (sum, a) => sum + a.points);

    return {
      'totalLessons': progressList.length,
      'completedLessons': progressList.where((p) => p.isCompleted).length,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
      'averageScore': averageScore,
      'totalTimeSpent': totalTimeSpent,
      'streak': streak,
      'achievements': {
        'unlocked': unlockedAchievements,
        'total': achievements.length,
        'points': totalPoints,
      },
      'progressByDay': _calculateDailyProgress(progressList),
      'subjectProgress': _calculateSubjectProgress(progressList),
    };
  }

  static Map<String, int> _calculateDailyProgress(
    List<UserLessonProgress> progressList,
  ) {
    final dailyProgress = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayProgress = progressList
          .where(
            (p) =>
                p.completedAt != null &&
                p.completedAt!.isAfter(dayStart) &&
                p.completedAt!.isBefore(dayEnd),
          )
          .length;

      dailyProgress[dateKey] = dayProgress;
    }

    return dailyProgress;
  }

  static Map<String, int> _calculateSubjectProgress(
    List<UserLessonProgress> progressList,
  ) {
    // This would be enhanced to categorize lessons by subject
    // For now, return a simple categorization
    return {
      'Media Literacy': progressList.where((p) => p.isCompleted).length,
      'Fake News Detection': 0,
      'Digital Safety': 0,
      'Critical Thinking': 0,
    };
  }

  // User Statistics
  static Stream<UserLearningStats?> getUserStats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_userStatsCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserLearningStats.fromFirestore(doc);
          }
          return null;
        });
  }

  static Future<void> _updateUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get all user progress
    final progressSnapshot = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    final progressList = progressSnapshot.docs
        .map((doc) => UserLessonProgress.fromFirestore(doc))
        .toList();

    // Calculate statistics
    final completedLessons = progressList.where((p) => p.isCompleted).length;
    final totalQuizzes = progressList.fold(
      0,
      (sum, p) => sum + p.quizAttempts.length,
    );
    final totalTimeSpent = progressList.fold(0, (sum, p) => sum + p.timeSpent);

    double averageScore = 0.0;
    if (totalQuizzes > 0) {
      final allAttempts = progressList.expand((p) => p.quizAttempts).toList();
      averageScore =
          allAttempts.fold(0.0, (sum, a) => sum + a.score) / allAttempts.length;
    }

    // Get achievements
    final achievementsSnapshot = await _firestore
        .collection(_achievementsCollection)
        .where('id', isGreaterThanOrEqualTo: '${user.uid}_')
        .where('id', isLessThan: '${user.uid}_\uf8ff')
        .get();

    final achievementPoints = achievementsSnapshot.docs.fold(0, (sum, doc) {
      final achievement = Achievement.fromFirestore(doc);
      return sum + (achievement.unlockedAt != null ? achievement.points : 0);
    });

    // Get streak data
    final streakDoc = await _firestore
        .collection(_streaksCollection)
        .doc(user.uid)
        .get();

    LearningStreak? streak;
    if (streakDoc.exists) {
      streak = LearningStreak.fromFirestore(streakDoc);
    } else {
      streak = LearningStreak(
        userId: user.uid,
        streakStartDate: DateTime.now(),
      );
    }

    // Update stats
    final stats = UserLearningStats(
      userId: user.uid,
      totalLessonsCompleted: completedLessons,
      totalQuizzesTaken: totalQuizzes,
      averageQuizScore: averageScore,
      totalTimeSpent: totalTimeSpent,
      totalAchievementPoints: achievementPoints,
      streak: streak,
      achievementIds: [],
      subjectProgress: {},
      lastUpdated: DateTime.now(),
    );

    await _firestore
        .collection(_userStatsCollection)
        .doc(user.uid)
        .set(stats.toFirestore(), SetOptions(merge: true));
  }

  static Future<void> _updateLearningStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final streakRef = _firestore.collection(_streaksCollection).doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(streakRef);

      LearningStreak streak;
      if (doc.exists) {
        streak = LearningStreak.fromFirestore(doc);

        if (streak.lastActivityDate != null) {
          final lastActivity = DateTime(
            streak.lastActivityDate!.year,
            streak.lastActivityDate!.month,
            streak.lastActivityDate!.day,
          );

          if (lastActivity.isAtSameMomentAs(today)) {
            // Already recorded activity today
            return;
          } else if (lastActivity.isAtSameMomentAs(
            today.subtract(const Duration(days: 1)),
          )) {
            // Consecutive day
            final newStreak = streak.currentStreak + 1;
            final updatedStreak = LearningStreak(
              userId: user.uid,
              currentStreak: newStreak,
              longestStreak: math.max(streak.longestStreak, newStreak),
              lastActivityDate: now,
              streakStartDate: streak.streakStartDate,
              totalActiveDays: streak.totalActiveDays + 1,
            );
            transaction.update(streakRef, updatedStreak.toFirestore());
          } else {
            // Streak broken, start new one
            final newStreak = LearningStreak(
              userId: user.uid,
              currentStreak: 1,
              longestStreak: streak.longestStreak,
              lastActivityDate: now,
              streakStartDate: today,
              totalActiveDays: streak.totalActiveDays + 1,
            );
            transaction.update(streakRef, newStreak.toFirestore());
          }
        }
      } else {
        // First time
        streak = LearningStreak(
          userId: user.uid,
          currentStreak: 1,
          longestStreak: 1,
          lastActivityDate: now,
          streakStartDate: today,
          totalActiveDays: 1,
        );
        transaction.set(streakRef, streak.toFirestore());
      }
    });
  }

  // Analytics
  static Future<void> recordLessonView(String lessonId) async {
    await _firestore.collection(_lessonsCollection).doc(lessonId).update({
      'analytics.viewCount': FieldValue.increment(1),
    });
  }

  static Future<void> recordLessonRating(String lessonId, double rating) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Update user progress with rating
    final progressDocRef = _firestore
        .collection(_userProgressCollection)
        .doc('${user.uid}_$lessonId');

    await progressDocRef.update({'userRating': rating});

    // Update lesson analytics
    // This would typically be done with cloud functions for accuracy
    await _firestore.collection(_lessonsCollection).doc(lessonId).update({
      'analytics.ratingCount': FieldValue.increment(1),
    });
  }
}
