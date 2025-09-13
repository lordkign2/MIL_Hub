// /features/learn/screens/learn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lessons.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_card_shimmer.dart';
import '../services/learning_service.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;

  final LearningService _learningService = LearningService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();

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

    _loadData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Simulate loading delay for smooth animation
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
      _headerController.forward();

      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _listController.forward();
      }
    }
  }

  List<dynamic> get _filteredLessons {
    var filtered = lessons.where((lesson) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!lesson.title.toLowerCase().contains(searchLower) &&
            !lesson.subtitle.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All') {
        switch (_selectedCategory) {
          case 'Beginner':
            return lesson.progress < 25;
          case 'Intermediate':
            return lesson.progress >= 25 && lesson.progress < 50;
          case 'Advanced':
            return lesson.progress >= 50 && lesson.progress < 100;
          case 'Completed':
            return lesson.progress >= 100;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _handleBookmark(dynamic lesson) {
    HapticFeedback.lightImpact();
    // TODO: Implement bookmark functionality with learning service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson bookmarked: ${lesson.title}'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShare(dynamic lesson) {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${lesson.title}'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar with search
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
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
                            Colors.purple.withOpacity(0.3),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      // Replaced FlexibleSpaceBar with custom implementation
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isSearching) ...[
                              // Title for non-search state
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Opacity(
                                  opacity: _headerAnimation.value,
                                  child: const Text(
                                    "📚 Learn",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_isSearching) ...[
                              // Search bar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: _handleSearch,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search lessons...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      onPressed: _clearSearch,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() => _isSearching = true);
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _clearSearch,
                ),
            ],
          ),

          // Category filter chips
          if (!_isLoading)
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        ? Colors.purple
                                        : Colors.white.withOpacity(0.1),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.purple
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

          // Loading state
          if (_isLoading)
            const SliverToBoxAdapter(child: LessonListShimmer(itemCount: 5))
          // Lessons list
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filteredLessons = _filteredLessons;

                  if (filteredLessons.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No lessons found for "$_searchQuery"'
                                : 'No lessons found in $_selectedCategory',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (index >= filteredLessons.length) return null;

                  final lesson = filteredLessons[index];

                  return AnimatedBuilder(
                    animation: _listAnimation,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      final animationValue = (_listAnimation.value - delay)
                          .clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: index == filteredLessons.length - 1
                                  ? 20
                                  : 0,
                            ),
                            child: ElegantLessonCard(
                              lesson: lesson,
                              onBookmark: () => _handleBookmark(lesson),
                              onShare: () => _handleShare(lesson),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: _filteredLessons.isEmpty
                    ? 1
                    : _filteredLessons.length,
              ),
            ),
        ],
      ),
    );
  }
}
