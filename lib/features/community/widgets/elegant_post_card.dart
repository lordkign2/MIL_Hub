import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';
import '../../../constants/global_variables.dart';
import './like_animation_widget.dart';

class ElegantPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final bool showActions;

  const ElegantPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onShare,
    this.onComment,
    this.showActions = true,
  });

  @override
  State<ElegantPostCard> createState() => _ElegantPostCardState();
}

class _ElegantPostCardState extends State<ElegantPostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _shareAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _shareScaleAnimation;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLikeState();
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _shareAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _shareScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _shareAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeLikeState() {
    final currentUser = FirebaseAuth.instance.currentUser;
    _isLiked =
        currentUser != null && widget.post.likedBy.contains(currentUser.uid);
    _likeCount = widget.post.likeCount;
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _shareAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Animate like button
    if (_isLiked) {
      await _likeAnimationController.forward();
      await _likeAnimationController.reverse();
    }

    try {
      await CommunityService.toggleLike(widget.post.id);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  Future<void> _handleShare() async {
    _shareAnimationController.forward().then((_) {
      _shareAnimationController.reverse();
    });

    if (widget.onShare != null) {
      widget.onShare!();
    } else {
      // Default share functionality
      _showShareDialog();
    }
  }

  void _showShareDialog() {
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
              'Share Post',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildShareOption(Icons.copy, 'Copy Link', () {
              // Copy functionality
              Navigator.pop(context);
            }),
            _buildShareOption(Icons.message, 'Share via Message', () {
              // Share via message
              Navigator.pop(context);
            }),
            _buildShareOption(Icons.more_horiz, 'More Options', () {
              // More sharing options
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showPostOptions() {
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
            _buildPostOption(Icons.bookmark_border, 'Save Post', () {
              Navigator.pop(context);
            }),
            _buildPostOption(Icons.flag_outlined, 'Report Post', () {
              Navigator.pop(context);
              _showReportDialog();
            }),
            _buildPostOption(Icons.link, 'Copy Link', () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPostOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Why are you reporting this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle report
              CommunityService.reportContent(
                contentId: widget.post.id,
                contentType: 'post',
                reason: 'inappropriate_content',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post reported successfully')),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          if (widget.post.tags.isNotEmpty) _buildTags(),
          if (widget.showActions) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.post.authorId}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.post.authorPhoto == null
                    ? GlobalVariables.appBarGradient
                    : null,
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundImage: widget.post.authorPhoto != null
                    ? NetworkImage(widget.post.authorPhoto!)
                    : null,
                backgroundColor: Colors.transparent,
                child: widget.post.authorPhoto == null
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.post.authorTitle != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GlobalVariables.secondaryColor.withOpacity(
                            0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.post.authorTitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: GlobalVariables.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (widget.post.isPinned) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.push_pin, size: 16, color: Colors.amber[400]),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.timeAgo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showPostOptions,
            icon: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (widget.post.mediaUrls != null &&
              widget.post.mediaUrls!.isNotEmpty)
            _buildMediaSection(),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    // This would handle different types of media (images, videos, etc.)
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[800],
      ),
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: widget.post.tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_likeCount > 0 || widget.post.commentCount > 0)
            _buildEngagementStats(),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (_likeCount > 0) ...[
            Icon(Icons.favorite, size: 16, color: Colors.red[400]),
            const SizedBox(width: 4),
            LikeCounterWidget(count: _likeCount, isLiked: _isLiked),
          ],
          const Spacer(),
          if (widget.post.commentCount > 0)
            Text(
              '${widget.post.commentCount} comments',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          if (widget.post.shareCount > 0) ...[
            const SizedBox(width: 16),
            Text(
              '${widget.post.shareCount} shares',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: LikeAnimationWidget(
            isLiked: _isLiked,
            onTap: _handleLike,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleLike,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red[400] : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Like',
                        style: TextStyle(
                          color: _isLiked ? Colors.red[400] : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onComment,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Comment',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _shareScaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _shareScaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleShare,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
