import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/community_service.dart';
import '../../../constants/global_variables.dart';

class ElegantCommentInput extends StatefulWidget {
  final String postId;
  final String? replyToCommentId;
  final String? replyToUsername;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onCancel;

  const ElegantCommentInput({
    super.key,
    required this.postId,
    this.replyToCommentId,
    this.replyToUsername,
    this.onCommentAdded,
    this.onCancel,
  });

  @override
  State<ElegantCommentInput> createState() => _ElegantCommentInputState();
}

class _ElegantCommentInputState extends State<ElegantCommentInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isExpanded = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _focusNode.addListener(_onFocusChange);

    if (widget.replyToUsername != null) {
      _controller.text = '@${widget.replyToUsername} ';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await CommunityService.addComment(
        postId: widget.postId,
        content: content,
        parentCommentId: widget.replyToCommentId,
      );

      _controller.clear();
      _focusNode.unfocus();

      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!();
      }

      setState(() {
        _isExpanded = false;
      });
      _animationController.reverse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
      }
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _cancel() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();

    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyToUsername != null) _buildReplyHeader(),
          _buildCommentInput(),
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) => SizeTransition(
              sizeFactor: _slideAnimation,
              child: _buildExpandedActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: Colors.blue[300]),
          const SizedBox(width: 8),
          Text(
            'Replying to ${widget.replyToUsername}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[300],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancel,
            child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // User avatar
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: currentUser?.photoURL == null
                ? GlobalVariables.appBarGradient
                : null,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            backgroundColor: Colors.transparent,
            child: currentUser?.photoURL == null
                ? const Icon(Icons.person, color: Colors.white, size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(24),
              border: _focusNode.hasFocus
                  ? Border.all(color: Colors.blue, width: 1)
                  : null,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              maxLines: _isExpanded ? 4 : 1,
              decoration: InputDecoration(
                hintText: widget.replyToUsername != null
                    ? 'Write a reply...'
                    : 'Write a comment...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isPosting ? null : _postComment,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _controller.text.trim().isNotEmpty
                      ? GlobalVariables.appBarGradient
                      : null,
                  color: _controller.text.trim().isEmpty
                      ? Colors.grey[700]
                      : null,
                  shape: BoxShape.circle,
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: _controller.text.trim().isNotEmpty
                            ? Colors.white
                            : Colors.grey[500],
                        size: 20,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedActions() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Action buttons row
          Row(
            children: [
              _buildActionButton(
                icon: Icons.emoji_emotions_outlined,
                label: 'Emoji',
                onTap: () {
                  // Show emoji picker
                },
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.gif_box_outlined,
                label: 'GIF',
                onTap: () {
                  // Show GIF picker
                },
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.image_outlined,
                label: 'Image',
                onTap: () {
                  // Show image picker
                },
              ),
              const Spacer(),
              if (_isExpanded) ...[
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty
                      ? _postComment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Post'),
                ),
              ],
            ],
          ),

          // Character counter (when expanded and has content)
          if (_isExpanded && _controller.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length}/500',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.text.length > 500
                      ? Colors.red[400]
                      : Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
