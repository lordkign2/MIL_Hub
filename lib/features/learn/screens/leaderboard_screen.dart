import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final Color themeColor;

  const LeaderboardScreen({super.key, this.themeColor = Colors.purple});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final GamificationService _gamificationService = GamificationService();

  LeaderboardType _selectedType = LeaderboardType.points;
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.weekly;
  Leaderboard? _currentLeaderboard;
  int _userRank = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadLeaderboard();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            _selectedPeriod = LeaderboardPeriod.daily;
            break;
          case 1:
            _selectedPeriod = LeaderboardPeriod.weekly;
            break;
          case 2:
            _selectedPeriod = LeaderboardPeriod.monthly;
            break;
          case 3:
            _selectedPeriod = LeaderboardPeriod.allTime;
            break;
        }
        _loadLeaderboard();
      }
    });
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final leaderboard = await _gamificationService.getLeaderboard(
        _selectedType,
        _selectedPeriod,
      );
      final userRank = await _gamificationService.getUserRank(
        'current_user',
        _selectedType,
        _selectedPeriod,
      );

      setState(() {
        _currentLeaderboard = leaderboard;
        _userRank = userRank;
        _isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: Container(
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
                    bottom: 80,
                    top: 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Title
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTypeSelector(),
                      if (_userRank > 0) ...[
                        const SizedBox(height: 12),
                        _buildUserRankCard(),
                      ],
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: widget.themeColor,
                tabs: const [
                  Tab(text: 'DAILY'),
                  Tab(text: 'WEEKLY'),
                  Tab(text: 'MONTHLY'),
                  Tab(text: 'ALL TIME'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: widget.themeColor))
            : _buildLeaderboardContent(),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: LeaderboardType.values.map((type) {
          final isSelected = type == _selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedType = type);
                _loadLeaderboard();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? widget.themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _getTypeDisplayName(type),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserRankCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: widget.themeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Your Rank: #$_userRank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_currentLeaderboard == null || _currentLeaderboard!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No leaderboard data available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Top 3 Podium
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                child: _buildPodium(),
              ),

              // Rest of the leaderboard
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900]!.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentLeaderboard!.entries.length > 3
                        ? _currentLeaderboard!.entries.length - 3
                        : 0,
                    itemBuilder: (context, index) {
                      final actualIndex = index + 3;
                      final entry = _currentLeaderboard!.entries[actualIndex];
                      final delay = index * 0.1;
                      final animationValue = (_fadeAnimation.value - delay)
                          .clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(50 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: _buildLeaderboardItem(entry, actualIndex),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodium() {
    final entries = _currentLeaderboard!.entries.take(3).toList();

    if (entries.isEmpty) return Container();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (entries.length > 1)
          Expanded(child: _buildPodiumPlace(entries[1], 2, 120)),

        // 1st Place
        if (entries.isNotEmpty)
          Expanded(child: _buildPodiumPlace(entries[0], 1, 150)),

        // 3rd Place
        if (entries.length > 2)
          Expanded(child: _buildPodiumPlace(entries[2], 3, 100)),
      ],
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, double height) {
    Color getPlaceColor() {
      switch (place) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey[300]!;
        case 3:
          return Colors.brown[300]!;
        default:
          return Colors.grey;
      }
    }

    IconData getPlaceIcon() {
      switch (place) {
        case 1:
          return Icons.emoji_events_rounded;
        case 2:
          return Icons.military_tech_rounded;
        case 3:
          return Icons.workspace_premium_rounded;
        default:
          return Icons.emoji_events_rounded;
      }
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [getPlaceColor(), getPlaceColor().withOpacity(0.6)],
                  ),
                  border: Border.all(color: getPlaceColor(), width: 2),
                ),
                child: Center(
                  child: Text(
                    entry.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Name
              Text(
                entry.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Points
              Text(
                '${entry.points}',
                style: TextStyle(
                  color: getPlaceColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Podium
              AnimatedContainer(
                duration: Duration(milliseconds: 800 + (place * 200)),
                width: double.infinity,
                height: height * _fadeAnimation.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      getPlaceColor().withOpacity(0.8),
                      getPlaceColor().withOpacity(0.4),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(getPlaceIcon(), color: Colors.white, size: 30),
                    const SizedBox(height: 4),
                    Text(
                      '#$place',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int index) {
    final isCurrentUser = entry.userId == 'current_user';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? widget.themeColor.withOpacity(0.2)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? widget.themeColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.themeColor.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: widget.themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [widget.themeColor, widget.themeColor.withOpacity(0.6)],
              ),
            ),
            child: Center(
              child: Text(
                entry.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${entry.lessonsCompleted} lessons • ${entry.currentStreak} day streak',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: TextStyle(
                  color: widget.themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getTypeDisplayName(_selectedType).toLowerCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.points:
        return 'Points';
      case LeaderboardType.lessons:
        return 'Lessons';
      case LeaderboardType.streaks:
        return 'Streaks';
      case LeaderboardType.quizScore:
        return 'Quiz';
      case LeaderboardType.timeSpent:
        return 'Time';
    }
  }
}
