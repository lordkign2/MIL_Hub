import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class EnhancedUserDashboard extends StatefulWidget {
  final Color themeColor;

  const EnhancedUserDashboard({super.key, this.themeColor = Colors.purple});

  @override
  State<EnhancedUserDashboard> createState() => _EnhancedUserDashboardState();
}

class _EnhancedUserDashboardState extends State<EnhancedUserDashboard>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;

  UserProfile? _userProfile;
  UserAnalytics? _analytics;
  List<UserActivity> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    try {
      print('🔄 Starting to load user data...');
      setState(() => _isLoading = true);

      // Get the current user profile first
      final currentUser = UserService.auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Current user found: ${currentUser.uid}');

      // Check if profile exists
      final profileDoc = await UserService.usersCollection
          .doc(currentUser.uid)
          .get();

      if (!profileDoc.exists) {
        print('🆕 Profile does not exist, initializing...');
        // Initialize new user profile
        await UserService.initializeNewUserProfile();
        print('✅ Profile initialized successfully');
        // Wait a moment for the profile to be created
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        print('✅ Profile exists, continuing...');
      }

      // Load analytics with fallback
      UserAnalytics? analytics;
      try {
        print('📊 Loading user analytics...');
        analytics = await UserService.getUserAnalytics();
        print('✅ Analytics loaded successfully');
      } catch (analyticsError) {
        print('⚠️ Error loading analytics: $analyticsError');
        // Create default analytics
        analytics = UserAnalytics(
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
        print('✅ Using default analytics');
      }

      print('🎯 Setting state with loaded data...');
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });

      print('🎬 Starting animations...');
      // Start animations
      _headerController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _cardsController.forward();
      print('🎉 Dashboard loaded successfully!');
    } catch (e) {
      print('💥 Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
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
        slivers: [
          _buildDashboardHeader(),
          _buildQuickStats(),
          _buildInsightsSection(),
          _buildActivitySection(),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: StreamBuilder<UserProfile?>(
        stream: UserService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          // Handle errors
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Container(
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
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  top: 100,
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
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
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final profile = snapshot.data;

          // Handle when no profile exists
          if (profile == null) {
            return Container(
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
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  top: 100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Setting up your profile...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
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
                          widget.themeColor.withOpacity(0.7),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                        top: 100,
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
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: profile?.photoURL != null
                                        ? Image.network(
                                            profile!.photoURL!,
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
                                      profile?.displayName ?? 'User',
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
                                      profile?.email ?? '',
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
                                        if (profile?.subscription.isPremium ==
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
          colors: [widget.themeColor.withOpacity(0.7), widget.themeColor],
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildStatusChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
                    const Text(
                      'Quick Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Current Streak',
                            '${_analytics?.currentStreak ?? 0}',
                            Icons.local_fire_department_rounded,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Activities',
                            '${_analytics?.totalActivities ?? 0}',
                            Icons.trending_up_rounded,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Time Spent',
                            '${(_analytics?.totalTimeSpent ?? 0) ~/ 60}h',
                            Icons.schedule_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Avg Score',
                            '${((_analytics?.averageScore ?? 0) * 100).toInt()}%',
                            Icons.emoji_events_rounded,
                            Colors.amber,
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to detailed stats
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), Colors.black.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
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
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
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
            color: color.withOpacity(0.2),
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
        color: Colors.grey[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
        color: color.withOpacity(0.2),
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
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start learning to see your progress here!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
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
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Edit Profile',
                            Icons.edit_rounded,
                            Colors.blue,
                            () => _navigateToEditProfile(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Achievements',
                            Icons.emoji_events_rounded,
                            Colors.amber,
                            () => _navigateToAchievements(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Statistics',
                            Icons.analytics_rounded,
                            Colors.green,
                            () => _navigateToStatistics(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Privacy',
                            Icons.security_rounded,
                            Colors.red,
                            () => _navigateToPrivacy(),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), Colors.black.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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

  // Navigation methods
  void _navigateToSettings() {
    // TODO: Navigate to settings screen
    print('Navigate to settings');
  }

  void _navigateToFullActivity() {
    // TODO: Navigate to full activity screen
    print('Navigate to full activity');
  }

  void _navigateToEditProfile() {
    // TODO: Navigate to edit profile screen
    print('Navigate to edit profile');
  }

  void _navigateToAchievements() {
    // TODO: Navigate to achievements screen
    print('Navigate to achievements');
  }

  void _navigateToStatistics() {
    // TODO: Navigate to statistics screen
    print('Navigate to statistics');
  }

  void _navigateToPrivacy() {
    // TODO: Navigate to privacy screen
    print('Navigate to privacy');
  }
}
