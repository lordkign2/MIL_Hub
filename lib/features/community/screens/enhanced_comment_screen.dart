import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';
import '../widgets/elegant_post_card.dart';
import '../widgets/elegant_comment_widget.dart';
import '../widgets/elegant_comment_input.dart';

class EnhancedCommentScreen extends StatefulWidget {
  final String postId;
  final PostModel? post;

  const EnhancedCommentScreen({super.key, required this.postId, this.post});

  @override
  State<EnhancedCommentScreen> createState() => _EnhancedCommentScreenState();
}

class _EnhancedCommentScreenState extends State<EnhancedCommentScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToUsername;
  bool _showCommentInput = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleReply(CommentModel comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUsername = comment.authorName;
      _showCommentInput = true;
    });
  }

  void _handleEdit(CommentModel comment) {
    // Show edit dialog
    _showEditCommentDialog(comment);
  }

  void _handleDelete(CommentModel comment) {
    CommunityService.deleteComment(widget.postId, comment.id);
  }

  void _showEditCommentDialog(CommentModel comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await CommunityService.updateComment(
                  widget.postId,
                  comment.id,
                  {'content': controller.text.trim()},
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
      _showCommentInput = false;
    });
  }

  void _onCommentAdded() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
      _showCommentInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showCommentInput = !_showCommentInput;
              });
            },
            icon: Icon(
              _showCommentInput
                  ? Icons.keyboard_hide
                  : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post preview at top
          if (widget.post != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ElegantPostCard(post: widget.post!, showActions: false),
            ),

          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: CommunityService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading comments',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
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
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your thoughts!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showCommentInput = true;
                            });
                          },
                          icon: const Icon(Icons.add_comment),
                          label: const Text('Add Comment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ElegantCommentWidget(
                      comment: comment,
                      onReply: () => _handleReply(comment),
                      onEdit: (c) => _handleEdit(c),
                      onDelete: (c) => _handleDelete(c),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          if (_showCommentInput)
            ElegantCommentInput(
              postId: widget.postId,
              replyToCommentId: _replyToCommentId,
              replyToUsername: _replyToUsername,
              onCommentAdded: _onCommentAdded,
              onCancel: _cancelReply,
            ),
        ],
      ),
    );
  }
}
