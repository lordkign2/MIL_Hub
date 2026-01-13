import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class EnhancedStreakScreen extends StatefulWidget {
  final Color themeColor;

  const EnhancedStreakScreen({super.key, this.themeColor = Colors.orange});

  @override
  State<EnhancedStreakScreen> createState() => _EnhancedStreakScreenState();
}

class _EnhancedStreakScreenState extends State<EnhancedStreakScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _progressController;
  late Animation<double> _flameAnimation;
  late Animation<double> _progressAnimation;

  final GamificationService _gamificationService = GamificationService();
  EnhancedStreak? _streak;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStreak();
  }

  void _initializeAnimations() {
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _flameAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _flameController.repeat(reverse: true);
  }

  Future<void> _loadStreak() async {
    try {
      final streak = await _gamificationService.getEnhancedStreak(
        'current_user',
      );
      setState(() {
        _streak = streak;
        _isLoading = false;
      });
      _progressController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: widget.themeColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildStreakDisplay(),
          _buildStreakCalendar(),
          _buildMilestones(),
          _buildStreakStats(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.themeColor, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Streak Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_streak?.canUseFreeze == true)
          IconButton(
            onPressed: _showFreezeDialog,
            icon: const Icon(Icons.ac_unit_rounded, color: Colors.lightBlue),
            tooltip: 'Use Streak Freeze',
          ),
      ],
    );
  }

  Widget _buildStreakDisplay() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _progressAnimation.value)),
            child: Opacity(
              opacity: _progressAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Main Streak Display
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.themeColor.withOpacity(0.3),
                            widget.themeColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _flameAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _flameAnimation.value,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 60,
                                    color: _streak!.currentStreak > 0
                                        ? widget.themeColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_streak!.currentStreak}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _streak!.currentStreak == 1
                                        ? 'Day'
                                        : 'Days',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Progress to Next Milestone
                    if (_streak!.daysUntilNextMilestone > 0)
                      _buildNextMilestoneProgress(),

                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Longest',
                            '${_streak!.longestStreak}',
                            Icons.emoji_events_rounded,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Active Days',
                            '${_streak!.totalActiveDays}',
                            Icons.calendar_today_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Freezes',
                            '${_streak!.freezeCount}',
                            Icons.ac_unit_rounded,
                            Colors.lightBlue,
                          ),
                        ),
                      ],
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

  Widget _buildNextMilestoneProgress() {
    final nextMilestone = _getNextMilestone();
    if (nextMilestone == null) return Container();

    final progress = _streak!.currentStreak / nextMilestone.days;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next: ${nextMilestone.title}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '${_streak!.daysUntilNextMilestone} days to go',
              style: TextStyle(
                color: widget.themeColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _progressAnimation.value)),
            child: Opacity(
              opacity: _progressAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: widget.themeColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Activity Calendar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCalendarGrid(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month - 2,
      1,
    ); // Show last 3 months
    final endDate = DateTime(now.year, now.month + 1, 0);

    final days = <DateTime>[];
    for (
      var date = startDate;
      date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      days.add(date);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        final isActive = _streak!.activityDates.any((activityDate) {
          return activityDate.year == date.year &&
              activityDate.month == date.month &&
              activityDate.day == date.day;
        });
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? widget.themeColor
                : isToday
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestones() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 40 * (1 - _progressAnimation.value)),
            child: Opacity(
              opacity: _progressAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_rounded, color: widget.themeColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Streak Milestones',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._getAllMilestones().map(
                      (milestone) => _buildMilestoneItem(milestone),
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

  Widget _buildMilestoneItem(StreakMilestone milestone) {
    final isAchieved = _streak!.achievedMilestones.any(
      (m) => m.days == milestone.days,
    );
    final canAchieve = _streak!.currentStreak >= milestone.days;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved
            ? widget.themeColor.withOpacity(0.2)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAchieved
              ? widget.themeColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAchieved
                  ? widget.themeColor
                  : canAchieve
                  ? widget.themeColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
            child: Icon(
              isAchieved ? Icons.check_rounded : Icons.flag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    color: isAchieved ? Colors.white : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  milestone.description,
                  style: TextStyle(
                    color: isAchieved ? Colors.white70 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${milestone.days} days',
                style: TextStyle(
                  color: widget.themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+${milestone.bonusPoints} pts',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStats() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _progressAnimation.value)),
            child: Opacity(
              opacity: _progressAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: widget.themeColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Streak by Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_streak!.streaksByCategory.isNotEmpty)
                      ..._streak!.streaksByCategory.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${entry.value} activities',
                                style: TextStyle(
                                  color: widget.themeColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      const Text(
                        'No activity data available',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
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

  void _showFreezeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.ac_unit_rounded, color: Colors.lightBlue),
            const SizedBox(width: 12),
            const Text('Streak Freeze', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Use a streak freeze to protect your streak for one day. You have limited freezes available.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _gamificationService.useStreakFreeze(
                'current_user',
              );
              if (success) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Streak freeze used successfully!'),
                    backgroundColor: Colors.lightBlue,
                  ),
                );
                _loadStreak();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Use Freeze'),
          ),
        ],
      ),
    );
  }

  StreakMilestone? _getNextMilestone() {
    final allMilestones = _getAllMilestones();
    return allMilestones.firstWhere(
      (milestone) => milestone.days > _streak!.currentStreak,
      orElse: () => StreakMilestone(
        days: 0,
        title: '',
        description: '',
        badgeId: '',
        bonusPoints: 0,
      ),
    );
  }

  List<StreakMilestone> _getAllMilestones() {
    return [
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
        days: 14,
        title: 'Two Week Champion',
        description: '14-day learning streak',
        badgeId: 'streak_2_weeks',
        bonusPoints: 200,
      ),
      StreakMilestone(
        days: 30,
        title: 'Month Master',
        description: '30-day learning streak',
        badgeId: 'streak_month',
        bonusPoints: 500,
      ),
      StreakMilestone(
        days: 60,
        title: 'Dedication Expert',
        description: '60-day learning streak',
        badgeId: 'streak_2_months',
        bonusPoints: 1000,
      ),
      StreakMilestone(
        days: 100,
        title: 'Century Scholar',
        description: '100-day learning streak',
        badgeId: 'streak_century',
        bonusPoints: 2000,
      ),
      StreakMilestone(
        days: 365,
        title: 'Yearly Legend',
        description: '365-day learning streak',
        badgeId: 'streak_year',
        bonusPoints: 10000,
      ),
    ];
  }
}
