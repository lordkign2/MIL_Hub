import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import '../../../constants/global_variables.dart';

class ElegantPostCreator extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const ElegantPostCreator({super.key, this.onPostCreated});

  @override
  State<ElegantPostCreator> createState() => _ElegantPostCreatorState();
}

class _ElegantPostCreatorState extends State<ElegantPostCreator>
    with TickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  PostType _selectedType = PostType.text;
  PostPrivacy _selectedPrivacy = PostPrivacy.public;
  final List<String> _tags = [];
  bool _isPosting = false;
  int _characterCount = 0;

  static const int _maxCharacters = 1000;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _contentController.addListener(_updateCharacterCount);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _contentController.text.length;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      _showError('Post content cannot be empty');
      return;
    }

    if (_characterCount > _maxCharacters) {
      _showError('Post content exceeds maximum character limit');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await CommunityService.createPost(
        content: _contentController.text.trim(),
        type: _selectedType,
        tags: _tags,
        privacy: _selectedPrivacy,
      );

      if (mounted) {
        Navigator.pop(context);
        if (widget.onPostCreated != null) {
          widget.onPostCreated!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create post: $e');
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag.startsWith('#') ? tag : '#$tag');
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog.fullscreen(
            backgroundColor: Colors.black.withOpacity(0.95),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildAppBar(),
              body: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, color: Colors.white),
      ),
      title: const Text(
        'Create Post',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPosting || _contentController.text.trim().isEmpty
              ? null
              : _createPost,
          child: _isPosting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: _contentController.text.trim().isNotEmpty
                        ? GlobalVariables.appBarGradient
                        : null,
                    color: _contentController.text.trim().isEmpty
                        ? Colors.grey[700]
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Post',
                    style: TextStyle(
                      color: _contentController.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          _buildUserSection(currentUser),

          const SizedBox(height: 20),

          // Post type selector
          _buildPostTypeSelector(),

          const SizedBox(height: 20),

          // Content input
          _buildContentInput(),

          const SizedBox(height: 20),

          // Tags section
          _buildTagsSection(),

          const SizedBox(height: 20),

          // Privacy selector
          _buildPrivacySelector(),

          const SizedBox(height: 20),

          // Media options (for future implementation)
          if (_selectedType != PostType.text) _buildMediaOptions(),
        ],
      ),
    );
  }

  Widget _buildUserSection(User? currentUser) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: currentUser?.photoURL == null
                ? GlobalVariables.appBarGradient
                : null,
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            backgroundColor: Colors.transparent,
            child: currentUser?.photoURL == null
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.displayName ?? 'Anonymous User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GlobalVariables.secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Community Member',
                  style: TextStyle(
                    fontSize: 12,
                    color: GlobalVariables.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTypeOption(PostType.text, Icons.text_fields, 'Text'),
            const SizedBox(width: 12),
            _buildTypeOption(PostType.image, Icons.image, 'Image'),
            const SizedBox(width: 12),
            _buildTypeOption(PostType.poll, Icons.poll, 'Poll'),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(PostType type, IconData icon, String label) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? GlobalVariables.appBarGradient : null,
          color: !isSelected ? Colors.grey[800] : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: _contentFocusNode.hasFocus
                ? Border.all(color: Colors.blue, width: 2)
                : Border.all(color: Colors.grey[700]!),
          ),
          child: TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            maxLines: 8,
            maxLength: _maxCharacters,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$_characterCount/$_maxCharacters',
              style: TextStyle(
                fontSize: 12,
                color: _characterCount > _maxCharacters * 0.9
                    ? Colors.red[400]
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case PostType.text:
        return 'Share your thoughts about media literacy, fact-checking, or digital safety...';
      case PostType.image:
        return 'Add a caption for your image...';
      case PostType.video:
        return 'Describe your video content...';
      case PostType.poll:
        return 'Ask a question for the community to vote on...';
    }
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Tag input
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a tag (e.g., #FactCheck)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixText: '#',
                    prefixStyle: TextStyle(color: Colors.blue[300]),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add, color: Colors.blue),
            ),
          ],
        ),

        // Display tags
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],

        // Suggested tags
        const SizedBox(height: 12),
        Text(
          'Suggested:',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              [
                    '#MediaLiteracy',
                    '#FactCheck',
                    '#DigitalSafety',
                    '#CriticalThinking',
                    '#NewsVerification',
                  ]
                  .map(
                    (tag) => GestureDetector(
                      onTap: () {
                        if (!_tags.contains(tag) && _tags.length < 5) {
                          setState(() {
                            _tags.add(tag);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PostPrivacy>(
              value: _selectedPrivacy,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (PostPrivacy? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPrivacy = newValue;
                  });
                }
              },
              items: PostPrivacy.values.map((privacy) {
                return DropdownMenuItem<PostPrivacy>(
                  value: privacy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          _getPrivacyIcon(privacy),
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getPrivacyLabel(privacy),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPrivacyIcon(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return Icons.public;
      case PostPrivacy.friends:
        return Icons.group;
      case PostPrivacy.private:
        return Icons.lock;
    }
  }

  String _getPrivacyLabel(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return 'Public - Anyone can see this post';
      case PostPrivacy.friends:
        return 'Friends - Only friends can see this post';
      case PostPrivacy.private:
        return 'Private - Only you can see this post';
    }
  }

  Widget _buildMediaOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == PostType.image ? 'Add Images' : 'Create Poll',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[600]!,
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Feature coming soon',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
