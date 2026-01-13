import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
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
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
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
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                // Responsive avatar size based on screen width
                radius: MediaQuery.of(context).size.width > 400 ? 24 : 20,
                backgroundImage: widget.post.authorPhoto != null
                    ? NetworkImage(widget.post.authorPhoto!)
                    : null,
                backgroundColor: Colors.transparent,
                child: widget.post.authorPhoto == null
                    ? Icon(
                        Icons.person,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width > 400 ? 28 : 24,
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
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
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
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
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.content,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: Colors.white,
              height: 1.4,
            ),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
      child: Wrap(
        spacing: isSmallScreen ? 6 : 8,
        runSpacing: isSmallScreen ? 3 : 4,
        children: widget.post.tags
            .map(
              (tag) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          if (_likeCount > 0 || widget.post.commentCount > 0)
            _buildEngagementStats(),
          SizedBox(height: isSmallScreen ? 8 : 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          if (_likeCount > 0) ...[
            Icon(
              Icons.favorite,
              size: isSmallScreen ? 14 : 16,
              color: Colors.red[400],
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            LikeCounterWidget(count: _likeCount, isLiked: _isLiked),
          ],
          const Spacer(),
          if (widget.post.commentCount > 0)
            Text(
              '${widget.post.commentCount} comments',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          if (widget.post.shareCount > 0) ...[
            SizedBox(width: isSmallScreen ? 12 : 16),
            Text(
              '${widget.post.shareCount} shares',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isVerySmallScreen = MediaQuery.of(context).size.width < 300;

    // For very small screens, use a more compact layout
    if (isVerySmallScreen) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LikeAnimationWidget(
            isLiked: _isLiked,
            onTap: _handleLike,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red[400] : Colors.grey,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  'Like',
                  style: TextStyle(
                    color: _isLiked ? Colors.red[400] : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
              const SizedBox(height: 4),
              Text(
                'Comment',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _shareScaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _shareScaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_outlined, color: Colors.grey, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red[400] : Colors.grey,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'Like',
                        style: TextStyle(
                          color: _isLiked ? Colors.red[400] : Colors.grey,
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
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
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Comment',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
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
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: Colors.grey,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
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
