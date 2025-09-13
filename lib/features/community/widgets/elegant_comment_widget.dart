import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';
import '../../../constants/global_variables.dart';

class ElegantCommentWidget extends StatefulWidget {
  final CommentModel comment;
  final bool showReplies;
  final int depth;
  final VoidCallback? onReply;
  final Function(CommentModel)? onEdit;
  final Function(CommentModel)? onDelete;

  const ElegantCommentWidget({
    super.key,
    required this.comment,
    this.showReplies = true,
    this.depth = 0,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ElegantCommentWidget> createState() => _ElegantCommentWidgetState();
}

class _ElegantCommentWidgetState extends State<ElegantCommentWidget>
    with TickerProviderStateMixin {
  late AnimationController _reactionAnimationController;
  late Animation<double> _reactionScaleAnimation;

  bool _showReactionPicker = false;
  bool _showReplies = false;
  ReactionType? _userReaction;
  Map<ReactionType, int> _reactions = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeReactions();
  }

  void _initializeAnimations() {
    _reactionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _reactionScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _reactionAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeReactions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userReaction = widget.comment.getUserReaction(currentUser.uid);
    }
    _reactions = Map.from(widget.comment.reactions);
  }

  @override
  void dispose() {
    _reactionAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addReaction(ReactionType reaction) async {
    setState(() {
      // Remove previous reaction if exists
      if (_userReaction != null) {
        _reactions[_userReaction!] = (_reactions[_userReaction!] ?? 1) - 1;
        if (_reactions[_userReaction!]! <= 0) {
          _reactions.remove(_userReaction!);
        }
      }

      // Add new reaction
      _reactions[reaction] = (_reactions[reaction] ?? 0) + 1;
      _userReaction = reaction;
      _showReactionPicker = false;
    });

    _reactionAnimationController.forward().then((_) {
      _reactionAnimationController.reverse();
    });

    try {
      await CommunityService.addCommentReaction(
        widget.comment.postId,
        widget.comment.id,
        reaction,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _reactions[reaction] = (_reactions[reaction] ?? 1) - 1;
        if (_reactions[reaction]! <= 0) {
          _reactions.remove(reaction);
        }
        _userReaction = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add reaction: $e')));
      }
    }
  }

  void _toggleReactionPicker() {
    setState(() {
      _showReactionPicker = !_showReactionPicker;
    });
  }

  void _showCommentOptions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.comment.authorId;

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
            _buildCommentOption(Icons.reply, 'Reply', () {
              Navigator.pop(context);
              if (widget.onReply != null) widget.onReply!();
            }),
            _buildCommentOption(Icons.copy, 'Copy Text', () {
              Navigator.pop(context);
              // Copy to clipboard
            }),
            if (isOwner) ...[
              _buildCommentOption(Icons.edit, 'Edit', () {
                Navigator.pop(context);
                if (widget.onEdit != null) widget.onEdit!(widget.comment);
              }),
              _buildCommentOption(Icons.delete, 'Delete', () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              }),
            ],
            _buildCommentOption(Icons.flag_outlined, 'Report', () {
              Navigator.pop(context);
              _showReportDialog();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
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
              if (widget.onDelete != null) widget.onDelete!(widget.comment);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Report Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Why are you reporting this comment?',
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
              CommunityService.reportContent(
                contentId: widget.comment.id,
                contentType: 'comment',
                reason: 'inappropriate_content',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment reported successfully')),
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
      margin: EdgeInsets.only(
        left: widget.depth * 24.0,
        top: 8,
        right: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentCard(),
          if (_showReactionPicker) _buildReactionPicker(),
          if (widget.showReplies && widget.comment.replyCount > 0)
            _buildRepliesSection(),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: widget.comment.isPinned
            ? Border.all(color: Colors.amber, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(),
          _buildCommentContent(),
          _buildCommentActions(),
        ],
      ),
    );
  }

  Widget _buildCommentHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.comment.authorPhoto == null
                  ? GlobalVariables.appBarGradient
                  : null,
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: widget.comment.authorPhoto != null
                  ? NetworkImage(widget.comment.authorPhoto!)
                  : null,
              backgroundColor: Colors.transparent,
              child: widget.comment.authorPhoto == null
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.comment.authorTitle != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GlobalVariables.secondaryColor.withOpacity(
                            0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.comment.authorTitle!,
                          style: TextStyle(
                            fontSize: 10,
                            color: GlobalVariables.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (widget.comment.isPinned) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin, size: 12, color: Colors.amber[400]),
                    ],
                  ],
                ),
                Text(
                  widget.comment.timeAgo,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showCommentOptions,
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 16),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.comment.content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          if (widget.comment.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '(edited)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Reactions display
          if (_reactions.isNotEmpty) ...[
            _buildReactionsDisplay(),
            const SizedBox(width: 12),
          ],

          // Action buttons
          _buildActionButton(
            icon: Icons.add_reaction_outlined,
            label: 'React',
            onTap: _toggleReactionPicker,
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.reply_outlined,
            label: 'Reply',
            onTap: widget.onReply,
          ),

          const Spacer(),

          if (widget.comment.replyCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showReplies = !_showReplies;
                });
              },
              child: Text(
                '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReactionsDisplay() {
    return AnimatedBuilder(
      animation: _reactionScaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + (_reactionScaleAnimation.value * 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _reactions.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getReactionEmoji(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (entry.value > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReactionType.values.map((reaction) {
          return GestureDetector(
            onTap: () => _addReaction(reaction),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _userReaction == reaction
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                _getReactionEmoji(reaction),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRepliesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showReplies = !_showReplies;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showReplies
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showReplies)
            StreamBuilder<List<CommentModel>>(
              stream: CommunityService.getCommentsStream(
                widget.comment.postId,
                parentCommentId: widget.comment.id,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final replies = snapshot.data!;
                return Column(
                  children: replies
                      .map(
                        (reply) => ElegantCommentWidget(
                          comment: reply,
                          depth: widget.depth + 1,
                          showReplies: widget.depth < 2, // Limit nesting depth
                          onReply: widget.onReply,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getReactionEmoji(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.angry:
        return '😠';
      case ReactionType.sad:
        return '😢';
      case ReactionType.wow:
        return '😮';
    }
  }
}
