import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_lesson_model.dart';

enum AchievementType {
  completion,
  streak,
  mastery,
  explorer,
  perfectionist,
  speedster,
}

class UserLessonProgress {
  final String userId;
  final String lessonId;
  final LessonStatus status;
  final double progress; // 0.0 to 1.0
  final int timeSpent; // in seconds
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;
  final List<QuizAttempt> quizAttempts;
  final double? userRating;
  final bool isBookmarked;
  final Map<String, dynamic> metadata;

  UserLessonProgress({
    required this.userId,
    required this.lessonId,
    this.status = LessonStatus.available,
    this.progress = 0.0,
    this.timeSpent = 0,
    this.startedAt,
    this.completedAt,
    this.lastAccessedAt,
    this.quizAttempts = const [],
    this.userRating,
    this.isBookmarked = false,
    this.metadata = const {},
  });

  factory UserLessonProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserLessonProgress(
      userId: data['userId'] ?? '',
      lessonId: data['lessonId'] ?? '',
      status: LessonStatus.values.firstWhere(
        (s) => s.toString() == 'LessonStatus.${data['status']}',
        orElse: () => LessonStatus.available,
      ),
      progress: (data['progress'] ?? 0.0).toDouble(),
      timeSpent: data['timeSpent'] ?? 0,
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      lastAccessedAt: data['lastAccessedAt'] != null
          ? (data['lastAccessedAt'] as Timestamp).toDate()
          : null,
      quizAttempts: data['quizAttempts'] != null
          ? (data['quizAttempts'] as List)
                .map((q) => QuizAttempt.fromMap(q))
                .toList()
          : [],
      userRating: data['userRating']?.toDouble(),
      isBookmarked: data['isBookmarked'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'status': status.toString().split('.').last,
      'progress': progress,
      'timeSpent': timeSpent,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'lastAccessedAt': lastAccessedAt != null
          ? Timestamp.fromDate(lastAccessedAt!)
          : null,
      'quizAttempts': quizAttempts.map((q) => q.toMap()).toList(),
      'userRating': userRating,
      'isBookmarked': isBookmarked,
      'metadata': metadata,
    };
  }

  UserLessonProgress copyWith({
    String? userId,
    String? lessonId,
    LessonStatus? status,
    double? progress,
    int? timeSpent,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastAccessedAt,
    List<QuizAttempt>? quizAttempts,
    double? userRating,
    bool? isBookmarked,
    Map<String, dynamic>? metadata,
  }) {
    return UserLessonProgress(
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      timeSpent: timeSpent ?? this.timeSpent,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      userRating: userRating ?? this.userRating,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters
  bool get isCompleted =>
      status == LessonStatus.completed || status == LessonStatus.mastered;
  bool get isInProgress => status == LessonStatus.inProgress;
  bool get isLocked => status == LessonStatus.locked;
  bool get hasBestScore => quizAttempts.isNotEmpty;

  double get bestQuizScore {
    if (quizAttempts.isEmpty) return 0.0;
    return quizAttempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
  }

  QuizAttempt? get latestQuizAttempt {
    if (quizAttempts.isEmpty) return null;
    return quizAttempts.reduce(
      (a, b) => a.completedAt.isAfter(b.completedAt) ? a : b,
    );
  }

  String get progressText => '${(progress * 100).toInt()}%';
}

class QuizAttempt {
  final String id;
  final String lessonId;
  final String userId;
  final double score; // 0.0 to 1.0
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent; // in seconds
  final DateTime startedAt;
  final DateTime completedAt;
  final List<QuestionAttempt> questionAttempts;
  final Map<String, dynamic> analytics;

  QuizAttempt({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.startedAt,
    required this.completedAt,
    this.questionAttempts = const [],
    this.analytics = const {},
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> data) {
    return QuizAttempt(
      id: data['id'] ?? '',
      lessonId: data['lessonId'] ?? '',
      userId: data['userId'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      timeSpent: data['timeSpent'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      questionAttempts: data['questionAttempts'] != null
          ? (data['questionAttempts'] as List)
                .map((q) => QuestionAttempt.fromMap(q))
                .toList()
          : [],
      analytics: data['analytics'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpent': timeSpent,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'questionAttempts': questionAttempts.map((q) => q.toMap()).toList(),
      'analytics': analytics,
    };
  }

  QuizAttempt copyWith({
    String? id,
    String? lessonId,
    String? userId,
    double? score,
    int? totalQuestions,
    int? correctAnswers,
    int? timeSpent,
    DateTime? startedAt,
    DateTime? completedAt,
    List<QuestionAttempt>? questionAttempts,
    Map<String, dynamic>? analytics,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeSpent: timeSpent ?? this.timeSpent,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      questionAttempts: questionAttempts ?? this.questionAttempts,
      analytics: analytics ?? this.analytics,
    );
  }

  // Getters
  double get percentage => score * 100;
  bool get isPassed => score >= 0.7; // 70% passing grade
  String get gradeLabel {
    if (score >= 0.9) return 'A';
    if (score >= 0.8) return 'B';
    if (score >= 0.7) return 'C';
    if (score >= 0.6) return 'D';
    return 'F';
  }
}

class QuestionAttempt {
  final String questionId;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final bool isCorrect;
  final int timeSpent; // in seconds
  final DateTime answeredAt;

  QuestionAttempt({
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory QuestionAttempt.fromMap(Map<String, dynamic> data) {
    return QuestionAttempt(
      questionId: data['questionId'] ?? '',
      userAnswer: data['userAnswer'],
      correctAnswer: data['correctAnswer'],
      isCorrect: data['isCorrect'] ?? false,
      timeSpent: data['timeSpent'] ?? 0,
      answeredAt: (data['answeredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }
}

class LearningStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final DateTime streakStartDate;
  final int totalActiveDays;

  LearningStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    required this.streakStartDate,
    this.totalActiveDays = 0,
  });

  factory LearningStreak.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LearningStreak(
      userId: data['userId'] ?? '',
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActivityDate: data['lastActivityDate'] != null
          ? (data['lastActivityDate'] as Timestamp).toDate()
          : null,
      streakStartDate: (data['streakStartDate'] as Timestamp).toDate(),
      totalActiveDays: data['totalActiveDays'] ?? 0,
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

  bool get isStreakBroken {
    if (lastActivityDate == null) return true;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastActivityDate!.isBefore(yesterday);
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final DateTime? unlockedAt;
  final int points;
  final String rarity; // 'common', 'rare', 'epic', 'legendary'

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    required this.criteria,
    this.unlockedAt,
    this.points = 10,
    this.rarity = 'common',
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Achievement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? '',
      type: AchievementType.values.firstWhere(
        (t) => t.toString() == 'AchievementType.${data['type']}',
        orElse: () => AchievementType.completion,
      ),
      criteria: data['criteria'] ?? {},
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      points: data['points'] ?? 10,
      rarity: data['rarity'] ?? 'common',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'type': type.toString().split('.').last,
      'criteria': criteria,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'points': points,
      'rarity': rarity,
    };
  }

  bool get isUnlocked => unlockedAt != null;
}

class UserLearningStats {
  final String userId;
  final int totalLessonsCompleted;
  final int totalQuizzesTaken;
  final double averageQuizScore;
  final int totalTimeSpent; // in seconds
  final int totalAchievementPoints;
  final LearningStreak streak;
  final List<String> achievementIds;
  final Map<String, int> subjectProgress; // subject -> lessons completed
  final DateTime lastUpdated;

  UserLearningStats({
    required this.userId,
    this.totalLessonsCompleted = 0,
    this.totalQuizzesTaken = 0,
    this.averageQuizScore = 0.0,
    this.totalTimeSpent = 0,
    this.totalAchievementPoints = 0,
    required this.streak,
    this.achievementIds = const [],
    this.subjectProgress = const {},
    required this.lastUpdated,
  });

  factory UserLearningStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserLearningStats(
      userId: data['userId'] ?? '',
      totalLessonsCompleted: data['totalLessonsCompleted'] ?? 0,
      totalQuizzesTaken: data['totalQuizzesTaken'] ?? 0,
      averageQuizScore: (data['averageQuizScore'] ?? 0.0).toDouble(),
      totalTimeSpent: data['totalTimeSpent'] ?? 0,
      totalAchievementPoints: data['totalAchievementPoints'] ?? 0,
      streak: LearningStreak.fromFirestore(
        doc,
      ), // Assuming streak data is embedded
      achievementIds: data['achievementIds'] != null
          ? List<String>.from(data['achievementIds'])
          : [],
      subjectProgress: data['subjectProgress'] != null
          ? Map<String, int>.from(data['subjectProgress'])
          : {},
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesTaken': totalQuizzesTaken,
      'averageQuizScore': averageQuizScore,
      'totalTimeSpent': totalTimeSpent,
      'totalAchievementPoints': totalAchievementPoints,
      'achievementIds': achievementIds,
      'subjectProgress': subjectProgress,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Getters
  String get totalTimeText {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get completionRate {
    // This would need total available lessons to calculate properly
    return totalLessonsCompleted / 100.0; // Placeholder
  }

  String get learnerLevel {
    if (totalAchievementPoints >= 1000) return 'Expert';
    if (totalAchievementPoints >= 500) return 'Advanced';
    if (totalAchievementPoints >= 200) return 'Intermediate';
    if (totalAchievementPoints >= 50) return 'Beginner';
    return 'Novice';
  }
}
