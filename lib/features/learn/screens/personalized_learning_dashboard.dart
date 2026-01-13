import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/enhanced_lesson_model.dart';
import '../models/user_progress_model.dart';
import '../services/learning_service.dart';
import '../widgets/progress_tracking_widget.dart';
import 'achievements_screen.dart';

class PersonalizedLearningDashboard extends StatefulWidget {
  final LearningService learningService;
  final Color themeColor;

  const PersonalizedLearningDashboard({
    super.key,
    required this.learningService,
    this.themeColor = Colors.purple,
  });

  @override
  State<PersonalizedLearningDashboard> createState() =>
      _PersonalizedLearningDashboardState();
}

class _PersonalizedLearningDashboardState
    extends State<PersonalizedLearningDashboard>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _chartController;

  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;
  late Animation<double> _chartAnimation;

  UserLearningStats? _userStats;
  LearningStreak? _streak;
  List<Achievement> _achievements = [];
  List<EnhancedLesson> _recommendedLessons = [];
  List<LearningInsight> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _cardsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.easeOutCubic),
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _loadDashboardData() async {
    try {
      // Simulate loading dashboard data
      await Future.delayed(const Duration(milliseconds: 1500));

      // In a real app, these would be loaded from the service
      final sampleStreak = LearningStreak(
        userId: 'current_user',
        currentStreak: 7,
        longestStreak: 15,
        lastActivityDate: DateTime.now().subtract(Duration(hours: 2)),
        streakStartDate: DateTime.now().subtract(Duration(days: 7)),
        totalActiveDays: 24,
      );

      _userStats = UserLearningStats(
        userId: 'current_user',
        totalLessonsCompleted: 24,
        totalQuizzesTaken: 18,
        averageQuizScore: 0.87,
        totalTimeSpent: 32 * 3600 + 45 * 60, // Convert to seconds
        totalAchievementPoints: 1240,
        streak: sampleStreak,
        achievementIds: ['1', '2'],
        subjectProgress: {'Programming': 15, 'Math': 9},
        lastUpdated: DateTime.now(),
      );

      _streak = sampleStreak;

      _achievements = _generateSampleAchievements();
      _recommendedLessons = _generateSampleRecommendations();
      _insights = _generateLearningInsights();

      setState(() => _isLoading = false);
      _startAnimations();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startAnimations() {
    _headerController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.themeColor),
              const SizedBox(height: 20),
              Text(
                'Loading your learning insights...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildDashboardHeader(),
          _buildQuickStats(),
          _buildInsightsSection(),
          _buildRecommendationsSection(),
          _buildProgressChart(),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _headerAnimation.value)),
            child: Opacity(
              opacity: _headerAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withOpacity(0.7),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 60,
                    top: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Title
                      const Text(
                        'Learning Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Level indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Level ${_getLevelFromPoints(_userStats?.totalAchievementPoints ?? 0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Settings button
                          IconButton(
                            onPressed: () => _showSettingsDialog(),
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (_userStats != null)
                        LinearProgressIndicator(
                          value:
                              (_getXpFromPoints(
                                    _userStats!.totalAchievementPoints,
                                  ) %
                                  1000) /
                              1000,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress tracking widget
                    if (_userStats != null)
                      ProgressTrackingWidget(
                        userStats: _userStats,
                        streak: _streak,
                        achievements: _achievements.take(3).toList(),
                        themeColor: widget.themeColor,
                        onAchievementTap: _navigateToAchievements,
                        onProgressTap: _showDetailedProgress,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 40 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: widget.themeColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Learning Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ..._insights.asMap().entries.map((entry) {
                      final index = entry.key;
                      final insight = entry.value;
                      final delay = index * 0.1;
                      final animationValue = (_cardsAnimation.value - delay)
                          .clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(30 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: _buildInsightCard(insight),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.recommend_rounded,
                          color: widget.themeColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Recommended for You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        TextButton(
                          onPressed: () => _showAllRecommendations(),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: widget.themeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _recommendedLessons[index];
                          final delay = index * 0.1;
                          final animationValue = (_cardsAnimation.value - delay)
                              .clamp(0.0, 1.0);

                          return Transform.translate(
                            offset: Offset(50 * (1 - animationValue), 0),
                            child: Opacity(
                              opacity: animationValue,
                              child: _buildRecommendationCard(lesson),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressChart() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 60 * (1 - _chartAnimation.value)),
            child: Opacity(
              opacity: _chartAnimation.value,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.themeColor.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.themeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: widget.themeColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Learning Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Simple progress visualization
                      _buildProgressVisualization(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(LearningInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInsightColor(insight.type).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getInsightColor(insight.type).withOpacity(0.2),
            ),
            child: Icon(
              _getInsightIcon(insight.type),
              color: _getInsightColor(insight.type),
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          if (insight.actionText != null)
            TextButton(
              onPressed: () => _handleInsightAction(insight),
              child: Text(
                insight.actionText!,
                style: TextStyle(
                  color: _getInsightColor(insight.type),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(EnhancedLesson lesson) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.themeColor.withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openLesson(lesson),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor,
                        widget.themeColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Icon(
                    _getLessonIcon(lesson.iconName),
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.estimatedDuration} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Recommended',
                    style: TextStyle(
                      color: widget.themeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressVisualization() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Weekly progress bars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final height = (30 + math.Random().nextInt(60))
                          .toDouble();
                      final isToday = index == 6;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: Duration(
                                  milliseconds: 800 + (index * 100),
                                ),
                                height: height * _chartAnimation.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isToday
                                        ? [
                                            widget.themeColor,
                                            widget.themeColor.withOpacity(0.5),
                                          ]
                                        : [
                                            Colors.grey[600]!,
                                            Colors.grey[800]!,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                                style: TextStyle(
                                  color: isToday
                                      ? widget.themeColor
                                      : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Summary stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatItem(
                'Lessons',
                '${_userStats?.totalLessonsCompleted ?? 0}',
              ),
              const SizedBox(height: 8),
              _buildStatItem(
                'Hours',
                '${(_userStats?.totalTimeSpent ?? 0) ~/ 3600}',
              ),
              const SizedBox(height: 8),
              _buildStatItem(
                'Points',
                '${_userStats?.totalAchievementPoints ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: widget.themeColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // Helper methods
  int _getLevelFromPoints(int points) {
    if (points >= 2000) return 5;
    if (points >= 1500) return 4;
    if (points >= 1000) return 3;
    if (points >= 500) return 2;
    if (points >= 100) return 1;
    return 0;
  }

  int _getXpFromPoints(int points) {
    // Convert achievement points to experience points
    return points * 2;
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Colors.amber;
      case InsightType.recommendation:
        return widget.themeColor;
      case InsightType.streak:
        return Colors.orange;
      case InsightType.improvement:
        return Colors.green;
      case InsightType.milestone:
        return Colors.blue;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Icons.emoji_events_rounded;
      case InsightType.recommendation:
        return Icons.lightbulb_rounded;
      case InsightType.streak:
        return Icons.local_fire_department_rounded;
      case InsightType.improvement:
        return Icons.trending_up_rounded;
      case InsightType.milestone:
        return Icons.flag_rounded;
    }
  }

  IconData _getLessonIcon(String category) {
    switch (category.toLowerCase()) {
      case 'basics':
        return Icons.play_circle_filled_rounded;
      case 'advanced':
        return Icons.auto_awesome_rounded;
      case 'practice':
        return Icons.fitness_center_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  // Sample data generators
  List<Achievement> _generateSampleAchievements() {
    return [
      Achievement(
        id: '1',
        title: 'First Steps',
        description: 'Complete your first lesson',
        iconName: 'first_lesson',
        points: 100,
        rarity: 'common',
        type: AchievementType.completion,
        unlockedAt: DateTime.now().subtract(Duration(days: 5)),
        criteria: {},
      ),
      Achievement(
        id: '2',
        title: 'Streak Master',
        description: 'Maintain a 7-day learning streak',
        iconName: 'streak_keeper',
        points: 250,
        rarity: 'rare',
        type: AchievementType.streak,
        unlockedAt: DateTime.now().subtract(Duration(days: 1)),
        criteria: {},
      ),
      Achievement(
        id: '3',
        title: 'Quiz Expert',
        description: 'Score 90% or higher on 5 quizzes',
        iconName: 'quiz_master',
        points: 300,
        rarity: 'epic',
        type: AchievementType.mastery,
        criteria: {},
      ),
    ];
  }

  List<EnhancedLesson> _generateSampleRecommendations() {
    return [
      EnhancedLesson(
        id: 'rec1',
        title: 'Advanced Functions',
        subtitle: 'Programming Concepts',
        description: 'Master advanced programming concepts',
        content: 'Sample content...',
        iconName: 'code',
        themeColor: widget.themeColor,
        difficulty: LessonDifficulty.intermediate,
        estimatedDuration: 15,
        order: 1,
        createdAt: DateTime.now(),
        analytics: LessonAnalytics(
          viewCount: 150,
          completionRate: 0.85,
          averageRating: 4.2,
          averageTimeSpent: 18,
          ratingCount: 45,
        ),
        tags: ['functions', 'programming'],
        learningObjectives: ['Understand functions', 'Apply concepts'],
        prerequisites: [],
        resources: [],
        questions: [],
      ),
      EnhancedLesson(
        id: 'rec2',
        title: 'Data Structures',
        subtitle: 'Computer Science',
        description: 'Understanding data organization',
        content: 'Sample content...',
        iconName: 'storage',
        themeColor: Colors.blue,
        difficulty: LessonDifficulty.beginner,
        estimatedDuration: 20,
        order: 2,
        createdAt: DateTime.now(),
        analytics: LessonAnalytics(
          viewCount: 200,
          completionRate: 0.92,
          averageRating: 4.5,
          averageTimeSpent: 22,
          ratingCount: 60,
        ),
        tags: ['data', 'structures'],
        learningObjectives: ['Learn data types', 'Organize information'],
        prerequisites: [],
        resources: [],
        questions: [],
      ),
    ];
  }

  List<LearningInsight> _generateLearningInsights() {
    return [
      LearningInsight(
        type: InsightType.streak,
        title: 'Great Streak!',
        description: 'You\'re on a 7-day learning streak. Keep it up!',
        actionText: 'Continue',
      ),
      LearningInsight(
        type: InsightType.improvement,
        title: 'Quiz Performance',
        description: 'Your quiz scores improved by 15% this week.',
        actionText: null,
      ),
      LearningInsight(
        type: InsightType.recommendation,
        title: 'Time to Level Up',
        description: 'Based on your progress, try intermediate lessons.',
        actionText: 'Explore',
      ),
    ];
  }

  // Navigation methods
  void _navigateToAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsScreen(
          achievements: _achievements,
          userStats: _userStats,
          themeColor: widget.themeColor,
        ),
      ),
    );
  }

  void _showDetailedProgress() {
    // TODO: Implement detailed progress screen
    HapticFeedback.lightImpact();
  }

  void _showAllRecommendations() {
    // TODO: Implement all recommendations screen
    HapticFeedback.lightImpact();
  }

  void _openLesson(EnhancedLesson lesson) {
    // TODO: Navigate to lesson detail screen
    HapticFeedback.lightImpact();
  }

  void _handleInsightAction(LearningInsight insight) {
    HapticFeedback.lightImpact();
    // TODO: Handle insight actions based on type
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Dashboard Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.notifications_rounded,
                color: widget.themeColor,
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeThumbColor: widget.themeColor,
              ),
            ),
            ListTile(
              leading: Icon(Icons.psychology_rounded, color: widget.themeColor),
              title: const Text(
                'Smart Recommendations',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeThumbColor: widget.themeColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: widget.themeColor)),
          ),
        ],
      ),
    );
  }
}

// Supporting classes
class LearningInsight {
  final InsightType type;
  final String title;
  final String description;
  final String? actionText;

  LearningInsight({
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
  });
}

enum InsightType { achievement, recommendation, streak, improvement, milestone }
