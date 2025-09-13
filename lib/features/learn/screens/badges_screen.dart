import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class BadgesScreen extends StatefulWidget {
  final Color themeColor;

  const BadgesScreen({super.key, this.themeColor = Colors.purple});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final GamificationService _gamificationService = GamificationService();

  List<Badge> _allBadges = [];
  List<Badge> _userBadges = [];
  BadgeCategory? _selectedCategory;
  BadgeRarity? _selectedRarity;
  bool _showUnlockedOnly = false;
  bool _isLoading = true;

  final List<BadgeCategory> _categories = BadgeCategory.values;
  final List<BadgeRarity> _rarities = BadgeRarity.values;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBadges();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  Future<void> _loadBadges() async {
    try {
      final allBadges = await _gamificationService.getAllBadges();
      final userBadges = await _gamificationService.getUserBadges(
        'current_user',
      );

      setState(() {
        _allBadges = allBadges;
        _userBadges = userBadges;
        _isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Badge> get _filteredBadges {
    var badges = _allBadges;

    if (_showUnlockedOnly) {
      final unlockedIds = _userBadges.map((b) => b.id).toSet();
      badges = badges.where((b) => unlockedIds.contains(b.id)).toList();
    }

    if (_selectedCategory != null) {
      badges = badges.where((b) => b.category == _selectedCategory).toList();
    }

    if (_selectedRarity != null) {
      badges = badges.where((b) => b.rarity == _selectedRarity).toList();
    }

    return badges;
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
        slivers: [_buildAppBar(), _buildFilters(), _buildBadgesGrid()],
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
                'Badge Collection',
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
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        _buildStatCard('Unlocked', '${_userBadges.length}'),
                        const SizedBox(width: 12),
                        _buildStatCard('Total', '${_allBadges.length}'),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Progress',
                          '${((_userBadges.length / _allBadges.length) * 100).toInt()}%',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Filter Row
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildRarityDropdown()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Toggle Switch
                    Row(
                      children: [
                        Switch(
                          value: _showUnlockedOnly,
                          onChanged: (value) {
                            setState(() => _showUnlockedOnly = value);
                          },
                          activeColor: widget.themeColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Show unlocked only',
                          style: TextStyle(color: Colors.white70),
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

  Widget _buildBadgesGrid() {
    final filteredBadges = _filteredBadges;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= filteredBadges.length) return null;

              final badge = filteredBadges[index];
              final isUnlocked = _userBadges.any((b) => b.id == badge.id);
              final delay = index * 0.1;
              final animationValue = (_animation.value - delay).clamp(0.0, 1.0);

              return Transform.scale(
                scale: animationValue,
                child: Opacity(
                  opacity: animationValue,
                  child: _buildBadgeCard(badge, isUnlocked),
                ),
              );
            }, childCount: filteredBadges.length),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.themeColor.withOpacity(0.3)),
        ),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: DropdownButton<BadgeCategory?>(
        value: _selectedCategory,
        hint: const Text('Category', style: TextStyle(color: Colors.white70)),
        dropdownColor: Colors.grey[900],
        underline: Container(),
        isExpanded: true,
        items: [
          const DropdownMenuItem<BadgeCategory?>(
            value: null,
            child: Text(
              'All Categories',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ..._categories
              .map(
                (category) => DropdownMenuItem<BadgeCategory?>(
                  value: category,
                  child: Text(
                    category.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ],
        onChanged: (value) => setState(() => _selectedCategory = value),
      ),
    );
  }

  Widget _buildRarityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: DropdownButton<BadgeRarity?>(
        value: _selectedRarity,
        hint: const Text('Rarity', style: TextStyle(color: Colors.white70)),
        dropdownColor: Colors.grey[900],
        underline: Container(),
        isExpanded: true,
        items: [
          const DropdownMenuItem<BadgeRarity?>(
            value: null,
            child: Text('All Rarities', style: TextStyle(color: Colors.white)),
          ),
          ..._rarities
              .map(
                (rarity) => DropdownMenuItem<BadgeRarity?>(
                  value: rarity,
                  child: Text(
                    rarity.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ],
        onChanged: (value) => setState(() => _selectedRarity = value),
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBadgeDetails(badge, isUnlocked);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    _getRarityColor(badge.rarity).withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ]
                : [
                    Colors.grey[800]!.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? _getRarityColor(badge.rarity).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [
                          _getRarityColor(badge.rarity),
                          _getRarityColor(badge.rarity).withOpacity(0.6),
                        ]
                      : [Colors.grey[600]!, Colors.grey[800]!],
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.iconName),
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 12),

            // Badge Name
            Text(
              badge.name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Rarity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.rarity.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: _getRarityColor(badge.rarity),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Points
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: isUnlocked ? Colors.amber : Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${badge.points}',
                  style: TextStyle(
                    color: isUnlocked ? Colors.amber : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Badge badge, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => BadgeDetailDialog(
        badge: badge,
        isUnlocked: isUnlocked,
        themeColor: widget.themeColor,
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.legendary:
        return Colors.purple;
      case BadgeRarity.epic:
        return Colors.deepPurple;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.common:
        return Colors.grey;
    }
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

class BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isUnlocked;
  final Color themeColor;

  const BadgeDetailDialog({
    super.key,
    required this.badge,
    required this.isUnlocked,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.6)],
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.iconName),
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              badge.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              badge.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
