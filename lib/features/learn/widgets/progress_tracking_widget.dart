import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';

class ProgressTrackingWidget extends StatefulWidget {
  final UserLearningStats? userStats;
  final LearningStreak? streak;
  final List<Achievement> achievements;
  final Color themeColor;
  final VoidCallback? onAchievementTap;
  final VoidCallback? onProgressTap;

  const ProgressTrackingWidget({
    super.key,
    this.userStats,
    this.streak,
    this.achievements = const [],
    this.themeColor = Colors.purple,
    this.onAchievementTap,
    this.onProgressTap,
  });

  @override
  State<ProgressTrackingWidget> createState() => _ProgressTrackingWidgetState();
}

class _ProgressTrackingWidgetState extends State<ProgressTrackingWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _streakController;
  late AnimationController _achievementController;
  late AnimationController _pulseController;

  late Animation<double> _progressAnimation;
  late Animation<double> _streakAnimation;
  late Animation<double> _achievementAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _streakController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _streakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.elasticOut),
    );

    _achievementAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _achievementController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _streakController.forward();
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _achievementController.forward();
    });

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _streakController.dispose();
    _achievementController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        border: Border.all(color: widget.themeColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              const Spacer(),
              if (widget.onProgressTap != null)
                GestureDetector(
                  onTap: widget.onProgressTap,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Overview
          if (widget.userStats != null) _buildProgressOverview(),

          const SizedBox(height: 20),

          // Streak Section
          if (widget.streak != null) _buildStreakSection(),

          const SizedBox(height: 20),

          // Recent Achievements
          if (widget.achievements.isNotEmpty) _buildAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    final stats = widget.userStats!;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lessons',
                    '${stats.totalLessonsCompleted}',
                    Icons.book_rounded,
                    widget.themeColor,
                    _progressAnimation.value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Quizzes',
                    '${stats.totalQuizzesTaken}',
                    Icons.quiz_rounded,
                    Colors.blue,
                    _progressAnimation.value * 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Score',
                    '${(stats.averageQuizScore * 100).round()}%',
                    Icons.grade_rounded,
                    Colors.green,
                    _progressAnimation.value * 0.9,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Time Spent',
                    stats.totalTimeText,
                    Icons.access_time_rounded,
                    Colors.orange,
                    _progressAnimation.value * 0.7,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double animationValue,
  ) {
    return Transform.scale(
      scale: 0.8 + (0.2 * animationValue),
      child: Opacity(
        opacity: animationValue,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    final streak = widget.streak!;

    return AnimatedBuilder(
      animation: _streakAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _streakAnimation.value)),
          child: Opacity(
            opacity: _streakAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.red.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  // Streak Icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: streak.currentStreak > 0
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange,
                                Colors.red.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // Streak Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${streak.currentStreak} Day Streak',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Longest: ${streak.longestStreak} days',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Streak Status
                  if (streak.isActiveToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    final recentAchievements = widget.achievements
        .where((a) => a.unlockedAt != null)
        .take(3)
        .toList();

    return AnimatedBuilder(
      animation: _achievementAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onAchievementTap != null)
                  GestureDetector(
                    onTap: widget.onAchievementTap,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: widget.themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Achievement List
            ...recentAchievements.asMap().entries.map((entry) {
              final index = entry.key;
              final achievement = entry.value;
              final delay = index * 0.2;
              final animationValue = (_achievementAnimation.value - delay)
                  .clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue,
                  child: _buildAchievementItem(achievement),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    Color getRarityColor() {
      switch (achievement.rarity) {
        case 'legendary':
          return Colors.purple;
        case 'epic':
          return Colors.deepPurple;
        case 'rare':
          return Colors.blue;
        case 'common':
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getRarityColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [getRarityColor(), getRarityColor().withOpacity(0.6)],
              ),
            ),
            child: Icon(
              _getAchievementIcon(achievement.iconName),
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Achievement Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getRarityColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${achievement.points}',
              style: TextStyle(
                color: getRarityColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'first_lesson':
        return Icons.play_circle_filled_rounded;
      case 'quiz_master':
        return Icons.quiz_rounded;
      case 'streak_keeper':
        return Icons.local_fire_department_rounded;
      case 'perfect_score':
        return Icons.grade_rounded;
      case 'speed_learner':
        return Icons.flash_on_rounded;
      case 'dedicated_learner':
        return Icons.school_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

// Circular Progress Widget
class CircularProgressWidget extends StatefulWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final String? centerText;
  final Widget? centerWidget;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.size = 120,
    this.strokeWidth = 8,
    this.centerText,
    this.centerWidget,
  });

  @override
  State<CircularProgressWidget> createState() => _CircularProgressWidgetState();
}

class _CircularProgressWidgetState extends State<CircularProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background Circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Progress Circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),

              // Center Content
              if (widget.centerWidget != null)
                widget.centerWidget!
              else if (widget.centerText != null)
                Text(
                  widget.centerText!,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.size * 0.15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
