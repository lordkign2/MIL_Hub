import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
import '../../admin/widgets/admin_access_widget.dart';
import '../../learn/screens/learn_screen.dart';
import '../../community/screens/community_screen.dart';
import '../../check/screens/check_screen.dart';
import '../presentation/providers/dashboard_provider.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_settings_screen.dart';
import '../screens/user_statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Color themeColor;

  const DashboardScreen({super.key, this.themeColor = Colors.purple});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;

  late final DashboardProvider _provider;
  
  // Dynamic getters routing straight to our Provider
  UserAnalytics? get _analytics => _provider.userAnalytics;
  bool get _isLoading => _provider.isLoading;

  @override
  void initState() {
    super.initState();
    _provider = DashboardProvider();
    
    // Wire up animations to play once the provider finishes loading
    _provider.loadDashboard().then((_) {
      if (mounted) {
        _headerController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _cardsController.forward();
        });
      }
    });
    
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _cardsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.easeOutCubic),
    );
  }


  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.themeColor),
              const SizedBox(height: 16),
              const Text(
                'Loading your dashboard...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback UI if something goes wrong
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildDashboardHeader(),
          _buildAdminAccessSection(),
          _buildQuickNavigationSection(),
          _buildQuickStats(),
          _buildInsightsSection(),
          _buildActivitySection(),
          _buildQuickActions(),
        ],
      ),
    );
      },
    );
  }

  Widget _buildDashboardHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: Builder(
        builder: (context) {
          final profile = _provider.userProfile;

          // Handle errors or missing profiles
          if (_provider.errorMessage != null) {
            // print('StreamBuilder error: ${snapshot.error}');
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.themeColor,
                    widget.themeColor.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  top: 80,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Welcome to MIL Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Setting up your profile...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle loading states
          if (_provider.isLoading || profile == null) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.themeColor,
                    widget.themeColor.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          return AnimatedBuilder(
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
                          widget.themeColor.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        top: 80,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          Row(
                            children: [
                              // Profile Image
                              Hero(
                                tag: 'profile_image',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: profile.photoURL != null
                                        ? Image.network(
                                            profile.photoURL!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return _buildDefaultAvatar();
                                                },
                                          )
                                        : _buildDefaultAvatar(),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Profile Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.email,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildStatusChip(
                                          'Level ${_analytics?.level ?? 1}',
                                          Icons.star_rounded,
                                          Colors.amber,
                                        ),
                                        const SizedBox(width: 8),
                                        if (profile.subscription.isPremium ==
                                            true)
                                          _buildStatusChip(
                                            'Premium',
                                            Icons.diamond_rounded,
                                            Colors.purple,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Settings Button
                              IconButton(
                                onPressed: () => _navigateToSettings(),
                                icon: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white70,
                                  size: 28,
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
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.themeColor.withValues(alpha: 0.7), widget.themeColor],
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildStatusChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Learning Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.themeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: widget.themeColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Level ${_analytics?.level ?? 1}',
                                style: TextStyle(
                                  color: widget.themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Stats Grid with better spacing
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _buildEnhancedStatCard(
                          'Current Streak',
                          '${_analytics?.currentStreak ?? 0}',
                          'days',
                          Icons.local_fire_department_rounded,
                          Colors.orange,
                          _analytics?.currentStreak != null &&
                                  _analytics!.currentStreak > 0
                              ? '+${_analytics!.currentStreak}'
                              : null,
                        ),
                        _buildEnhancedStatCard(
                          'Activities',
                          '${_analytics?.totalActivities ?? 0}',
                          'completed',
                          Icons.trending_up_rounded,
                          Colors.green,
                          _analytics?.weeklyActivities != null &&
                                  _analytics!.weeklyActivities > 0
                              ? '+${_analytics!.weeklyActivities} this week'
                              : null,
                        ),
                        _buildEnhancedStatCard(
                          'Time Spent',
                          '${(_analytics?.totalTimeSpent ?? 0) ~/ 60}',
                          'hours',
                          Icons.schedule_rounded,
                          Colors.blue,
                          _analytics?.totalTimeSpent != null &&
                                  _analytics!.totalTimeSpent > 0
                              ? '${_analytics!.totalTimeSpent % 60}m extra'
                              : null,
                        ),
                        _buildEnhancedStatCard(
                          'Avg Score',
                          '${((_analytics?.averageScore ?? 0) * 100).toInt()}',
                          'percent',
                          Icons.emoji_events_rounded,
                          Colors.amber,
                          _analytics?.averageScore != null &&
                                  _analytics!.averageScore > 0.8
                              ? 'Excellent!'
                              : _analytics?.averageScore != null &&
                                    _analytics!.averageScore > 0.6
                              ? 'Good job!'
                              : null,
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



  Widget _buildEnhancedStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToStatistics();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights_rounded, color: widget.themeColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Learning Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInsightItem(
                      'This Week',
                      '${_analytics?.weeklyActivities ?? 0} activities completed',
                      Icons.calendar_today_rounded,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      'Member Since',
                      '${_analytics?.joinedDays ?? 0} days ago',
                      Icons.cake_rounded,
                      Colors.pink,
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      'Last Active',
                      '${_analytics?.lastActiveAgo ?? 0} days ago',
                      Icons.access_time_rounded,
                      Colors.orange,
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

  Widget _buildInsightItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToFullActivity(),
                          child: Text(
                            'View All',
                            style: TextStyle(color: widget.themeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    StreamBuilder<List<UserActivity>>(
                      stream: UserService.getUserActivities(limit: 5),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final activities = snapshot.data ?? [];

                        if (activities.isEmpty) {
                          return _buildEmptyActivity();
                        }

                        return Column(
                          children: activities
                              .map((activity) => _buildActivityItem(activity))
                              .toList(),
                        );
                      },
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

  Widget _buildActivityItem(UserActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildActivityIcon(activity.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatActivityTime(activity.timestamp),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(ActivityType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ActivityType.lessonCompleted:
        icon = Icons.school_rounded;
        color = Colors.green;
        break;
      case ActivityType.quizPassed:
        icon = Icons.quiz_rounded;
        color = Colors.blue;
        break;
      case ActivityType.achievementUnlocked:
        icon = Icons.emoji_events_rounded;
        color = Colors.amber;
        break;
      case ActivityType.streakMaintained:
        icon = Icons.local_fire_department_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.circle_rounded;
        color = Colors.grey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start learning to see your progress here!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 60 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Account Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.settings_rounded,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Manage',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Actions Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.85,
                      children: [
                        _buildEnhancedActionButton(
                          'Edit Profile',
                          'Update your information',
                          Icons.edit_rounded,
                          Colors.blue,
                          () => _navigateToEditProfile(),
                        ),
                        _buildEnhancedActionButton(
                          'Achievements',
                          'View your badges',
                          Icons.emoji_events_rounded,
                          Colors.amber,
                          () => _navigateToAchievements(),
                        ),
                        _buildEnhancedActionButton(
                          'Statistics',
                          'Detailed analytics',
                          Icons.analytics_rounded,
                          Colors.green,
                          () => _navigateToStatistics(),
                        ),
                        _buildEnhancedActionButton(
                          'Privacy',
                          'Security settings',
                          Icons.security_rounded,
                          Colors.red,
                          () => _navigateToPrivacy(),
                        ),
                      ],
                    ),

                    // Additional bottom spacing
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildEnhancedActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // New dashboard sections
  Widget _buildAdminAccessSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: AdminAccessWidget(themeColor: widget.themeColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickNavigationSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 25 * (1 - _cardsAnimation.value)),
            child: Opacity(
              opacity: _cardsAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Navigation Cards Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: [
                        _buildNavigationCard(
                          'Learn',
                          'Lessons & Quizzes',
                          Icons.school_rounded,
                          Colors.purple,
                          () => _navigateToLearn(),
                        ),
                        _buildNavigationCard(
                          'Community',
                          'Posts & Discussions',
                          Icons.people_rounded,
                          Colors.blue,
                          () => _navigateToCommunity(),
                        ),
                        _buildNavigationCard(
                          'Check',
                          'Verify Content',
                          Icons.search_rounded,
                          Colors.indigo,
                          () => _navigateToCheck(),
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

  Widget _buildNavigationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToLearn() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LearnScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToCommunity() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToCheck() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CheckScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToSettings() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsScreen(themeColor: widget.themeColor)),
    );
  }

  void _navigateToFullActivity() {
    // TODO: Navigate to full activity screen
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfileScreen(themeColor: widget.themeColor)),
    );
  }

  void _navigateToAchievements() {
    // TODO: Navigate to achievements screen
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserStatisticsScreen(themeColor: widget.themeColor)),
    );
  }

  void _navigateToPrivacy() {
    // TODO: Navigate to privacy screen
    // print('Navigate to privacy');
  }
}
