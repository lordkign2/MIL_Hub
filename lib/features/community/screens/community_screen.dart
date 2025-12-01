import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import '../widgets/elegant_post_card.dart';
import '../widgets/elegant_post_creator.dart';
import './enhanced_comment_screen.dart';
import '../../../constants/global_variables.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  List<PostModel> _posts = [];
  List<String> _selectedTags = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadInitialPosts();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more posts only when scrolling down and near bottom
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 1000) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Using a simple approach for now - we'll stream the posts
      // In a production app, you'd implement proper pagination
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Implementation for loading more posts would go here
      // For now, we'll use the stream approach
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading more posts: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Debounce search if needed
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _showPostCreator() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

    showDialog(
      context: context,
      builder: (context) => ElegantPostCreator(
        onPostCreated: () {
          // Refresh posts or handle post creation
        },
      ),
    );
  }

  void _navigateToComments(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EnhancedCommentScreen(postId: post.id, post: post),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          if (_showSearch) _buildSearchSection(),
          _buildTrendingTags(),
          _buildPostsList(),
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _fabScaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _showPostCreator,
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.add),
            label: const Text('Post'),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SliverAppBar(
      expandedHeight: isSmallScreen ? 100 : 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        height: double.infinity,
        width: double.infinity,
        child: Container(
          padding: EdgeInsets.only(
            top: isSmallScreen ? 80 : 100,
            left: isSmallScreen ? 10 : 13,
            right: isSmallScreen ? 10 : 13,
            bottom: isSmallScreen ? 12 : 16,
          ),
          decoration: const BoxDecoration(
            gradient: GlobalVariables.appBarGradient,
          ),

          child: Text(
            '👥 Community Hub',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 18 : 20,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
            });
          },
          icon: Icon(
            _showSearch ? Icons.search_off : Icons.search,
            color: Colors.white,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        IconButton(
          onPressed: () {
            // Show filter options
            _showFilterDialog();
          },
          icon: Icon(
            Icons.filter_list,
            color: Colors.white,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search posts...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey,
              size: isSmallScreen ? 18 : 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingTags() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SliverToBoxAdapter(
      child: Container(
        height: isSmallScreen ? 50 : 60,
        margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
        child: FutureBuilder<List<String>>(
          future: CommunityService.getTrendingTags(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final tags = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
              ),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final isSelected = _selectedTags.contains(tag);

                return Container(
                  margin: EdgeInsets.only(right: isSmallScreen ? 6 : 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onSelected: (_) => _toggleTag(tag),
                    backgroundColor: Colors.grey[800],
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    visualDensity: isSmallScreen
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<List<PostModel>>(
      stream: CommunityService.getPostsStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading posts',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || _selectedTags.isNotEmpty
                          ? 'No posts found'
                          : 'No posts yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty || _selectedTags.isNotEmpty
                          ? 'Try adjusting your search or filters'
                          : 'Be the first to share something!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_searchQuery.isEmpty && _selectedTags.isEmpty) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showPostCreator,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = posts[index];
            return ElegantPostCard(
              post: post,
              onComment: () => _navigateToComments(post),
            );
          }, childCount: posts.length),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            const Text(
              'Post Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text(
                    'All',
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: true,
                  onSelected: (_) {},
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.blue,
                ),
                FilterChip(
                  label: const Text(
                    'Text',
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: false,
                  onSelected: (_) {},
                  backgroundColor: Colors.grey[800],
                ),
                FilterChip(
                  label: const Text(
                    'Images',
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: false,
                  onSelected: (_) {},
                  backgroundColor: Colors.grey[800],
                ),
                FilterChip(
                  label: const Text(
                    'Polls',
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: false,
                  onSelected: (_) {},
                  backgroundColor: Colors.grey[800],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTags.clear();
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Clear All',
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Apply',
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
