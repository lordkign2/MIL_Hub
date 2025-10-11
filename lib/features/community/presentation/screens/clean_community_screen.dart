import 'package:flutter/material.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_display.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../domain/entities/post_entity.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';

class CleanCommunityScreen extends StatefulWidget {
  const CleanCommunityScreen({super.key});

  @override
  State<CleanCommunityScreen> createState() => _CleanCommunityScreenState();
}

class _CleanCommunityScreenState extends State<CleanCommunityScreen> {
  late final CommunityBloc _communityBloc;

  @override
  void initState() {
    super.initState();
    _communityBloc = sl.get<CommunityBloc>();
    // Load posts when screen initializes
    _communityBloc.add(const LoadPostsEvent());
  }

  @override
  void dispose() {
    _communityBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _communityBloc.add(const RefreshPostsEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreatePostDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<CommunityState>(
        stream: _communityBloc.stream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _communityBloc.state;

          return switch (state) {
            CommunityInitial() || CommunityLoading() => const Center(
              child: LoadingIndicator(message: 'Loading community posts...'),
            ),
            PostsLoaded() => _buildPostsList(state),
            PostLoaded() => _buildSinglePostView(state),
            CommunityError() => ErrorDisplay(
              message: state.message,
              onRetry: () {
                _communityBloc.add(const LoadPostsEvent());
              },
            ),
            CommunityActionSuccess() => const Center(
              child: LoadingIndicator(message: 'Processing...'),
            ),
            _ => const Center(child: LoadingIndicator(message: 'Loading...')),
          };
        },
      ),
    );
  }

  Widget _buildPostsList(PostsLoaded state) {
    if (state.posts.isEmpty) {
      return EmptyStateWidget(
        title: 'No Posts Yet',
        message: 'Be the first to share something with the community!',
        icon: Icons.forum_outlined,
        action: ElevatedButton.icon(
          onPressed: _showCreatePostDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Post'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _communityBloc.add(const RefreshPostsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: state.posts.length,
        itemBuilder: (context, index) {
          final post = state.posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildSinglePostView(PostLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: _buildPostCard(state.post),
    );
  }

  Widget _buildPostCard(PostEntity post) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    post.authorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  const Icon(Icons.push_pin, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Post content
            Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppConstants.defaultPadding),

            // Post media (if any)
            if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.mediaUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: AppConstants.smallPadding,
                      ),
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppConstants.smallBorderRadius,
                          ),
                        ),
                        child: const Center(child: Icon(Icons.image, size: 48)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],

            // Tags
            if (post.tags.isNotEmpty) ...[
              Wrap(
                spacing: AppConstants.smallPadding,
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],

            // Actions
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up_outlined,
                  label: post.likeCount.toString(),
                  onPressed: () {
                    // In a real app, you would get the current user ID
                    _communityBloc.add(
                      LikePostEvent(postId: post.id, userId: 'current_user_id'),
                    );
                  },
                ),
                const SizedBox(width: AppConstants.largePadding),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: post.commentCount.toString(),
                  onPressed: () {
                    // Navigate to comments screen
                  },
                ),
                const SizedBox(width: AppConstants.largePadding),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: post.shareCount.toString(),
                  onPressed: () {
                    // Share functionality
                  },
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  label: post.viewCount.toString(),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _showCreatePostDialog() {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Post'),
          content: TextField(
            controller: contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What would you like to share with the community?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.trim().isNotEmpty) {
                  // In a real app, you would get the current user info
                  final post = PostEntity(
                    id: '', // Will be generated by the backend
                    authorId: 'current_user_id',
                    authorName: 'Current User',
                    content: contentController.text.trim(),
                    type: 'text',
                    privacy: 'public',
                    tags: [],
                    likeCount: 0,
                    commentCount: 0,
                    shareCount: 0,
                    viewCount: 0,
                    likedBy: [],
                    createdAt: DateTime.now(),
                    isPinned: false,
                    isArchived: false,
                    isReported: false,
                  );

                  _communityBloc.add(CreatePostEvent(post: post));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}
