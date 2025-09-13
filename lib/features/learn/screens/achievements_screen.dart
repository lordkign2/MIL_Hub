import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_progress_model.dart';
import '../widgets/progress_tracking_widget.dart';

class AchievementsScreen extends StatefulWidget {
  final List<Achievement> achievements;
  final UserLearningStats? userStats;
  final Color themeColor;

  const AchievementsScreen({
    super.key,
    required this.achievements,
    this.userStats,
    this.themeColor = Colors.purple,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Learning',
    'Quiz',
    'Streak',
    'Special',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'All') {
      return widget.achievements;
    }

    return widget.achievements.where((achievement) {
      switch (_selectedCategory) {
        case 'Learning':
          return achievement.type == AchievementType.completion;
        case 'Quiz':
          return achievement.type == AchievementType.mastery;
        case 'Streak':
          return achievement.type == AchievementType.streak;
        case 'Special':
          return achievement.type == AchievementType.explorer ||
              achievement.type == AchievementType.perfectionist ||
              achievement.type == AchievementType.speedster;
        default:
          return true;
      }
    }).toList();
  }

  int get _unlockedCount {
    return widget.achievements.where((a) => a.unlockedAt != null).length;
  }

  int get _totalPoints {
    return widget.achievements
        .where((a) => a.unlockedAt != null)
        .fold(0, (sum, a) => sum + a.points);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
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
                              'Achievements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Progress Circle
                                CircularProgressWidget(
                                  progress:
                                      _unlockedCount /
                                      widget.achievements.length,
                                  color: Colors.white,
                                  size: 60,
                                  strokeWidth: 4,
                                  centerText: '$_unlockedCount',
                                ),

                                const SizedBox(width: 20),

                                // Stats
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_unlockedCount/${widget.achievements.length} Unlocked',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_totalPoints Total Points',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _headerAnimation.value)),
                  child: Opacity(
                    opacity: _headerAnimation.value,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedCategory = category);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isSelected
                                      ? widget.themeColor
                                      : Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.themeColor
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Achievements List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievements = _filteredAchievements;

                if (achievements.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No achievements found in $_selectedCategory',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (index >= achievements.length) return null;

                final achievement = achievements[index];

                return AnimatedBuilder(
                  animation: _listAnimation,
                  builder: (context, child) {
                    final delay = index * 0.1;
                    final animationValue = (_listAnimation.value - delay).clamp(
                      0.0,
                      1.0,
                    );

                    return Transform.translate(
                      offset: Offset(50 * (1 - animationValue), 0),
                      child: Opacity(
                        opacity: animationValue,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: index == achievements.length - 1 ? 40 : 12,
                          ),
                          child: _buildAchievementCard(achievement),
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: _filteredAchievements.isEmpty
                  ? 1
                  : _filteredAchievements.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.unlockedAt != null;

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

    String getRarityLabel() {
      return achievement.rarity.toUpperCase();
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetails(achievement);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUnlocked
              ? getRarityColor().withOpacity(0.1)
              : Colors.grey[900]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? getRarityColor().withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Achievement Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          getRarityColor(),
                          getRarityColor().withOpacity(0.6),
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey[600]!, Colors.grey[800]!],
                      ),
              ),
              child: Icon(
                _getAchievementIcon(achievement.iconName),
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Achievement Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Rarity Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getRarityColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: getRarityColor().withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          getRarityLabel(),
                          style: TextStyle(
                            color: getRarityColor(),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white70 : Colors.white38,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Bottom Row
                  Row(
                    children: [
                      // Points
                      Icon(
                        Icons.stars_rounded,
                        color: isUnlocked ? Colors.amber : Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.points} pts',
                        style: TextStyle(
                          color: isUnlocked ? Colors.amber : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      // Status
                      if (isUnlocked)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unlocked',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AchievementDetailDialog(
        achievement: achievement,
        themeColor: widget.themeColor,
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

// Achievement Detail Dialog
class AchievementDetailDialog extends StatefulWidget {
  final Achievement achievement;
  final Color themeColor;

  const AchievementDetailDialog({
    super.key,
    required this.achievement,
    required this.themeColor,
  });

  @override
  State<AchievementDetailDialog> createState() =>
      _AchievementDetailDialogState();
}

class _AchievementDetailDialogState extends State<AchievementDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final isUnlocked = achievement.unlockedAt != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.themeColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Achievement Icon
                  Container(
                    width: 80,
                    height: 80,
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
                      _getAchievementIcon(achievement.iconName),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    achievement.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rarity',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              achievement.rarity.toUpperCase(),
                              style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Points',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${achievement.points}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isUnlocked) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Unlocked',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
