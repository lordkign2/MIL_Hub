import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_screen.dart';

class ImmersiveLessonDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  final Color color;
  final List<Map<String, Object>> questions;

  const ImmersiveLessonDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.questions,
  });

  @override
  State<ImmersiveLessonDetailScreen> createState() =>
      _ImmersiveLessonDetailScreenState();
}

class _ImmersiveLessonDetailScreenState
    extends State<ImmersiveLessonDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _progressController;
  late ScrollController _scrollController;

  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  bool _isScrolled = false;
  double _readingProgress = 0.0;
  int _estimatedReadingTime = 0;
  bool _isBookmarked = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    _initializeAnimationControllers();
    _initializeScrollController();
    _calculateReadingTime();

    // Start entrance animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _headerController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  void _initializeAnimationControllers() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
  }

  void _initializeScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Update reading progress
    if (maxScroll > 0) {
      final newProgress = (offset / maxScroll).clamp(0.0, 1.0);
      if (newProgress != _readingProgress) {
        setState(() => _readingProgress = newProgress);
        _progressController.animateTo(newProgress);
      }
    }

    // Update scroll state
    final isScrolled = offset > 100;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }

    // Mark as completed when reaching 90% of content
    if (_readingProgress >= 0.9 && !_isCompleted) {
      _markAsCompleted();
    }
  }

  void _calculateReadingTime() {
    final wordCount = widget.content.split(' ').length;
    _estimatedReadingTime = (wordCount / 200).ceil();
  }

  void _markAsCompleted() {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    HapticFeedback.mediumImpact();
  }

  void _startQuiz() {
    if (widget.questions.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) =>
              QuizScreen(color: widget.color, questions: widget.questions),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title.isEmpty || widget.content.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: widget.color,
          title: const Text("Lesson"),
        ),
        body: const Center(
          child: Text(
            "Error: Invalid lesson data",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Enhanced App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                expandedHeight: 220,
                floating: false,
                snap: false,
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
                                widget.color,
                                widget.color.withOpacity(0.7),
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 30,
                              top: 100,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dynamic title display based on scroll
                                if (!_isScrolled) ...[
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.schedule_rounded,
                                        text:
                                            '$_estimatedReadingTime min read',
                                      ),
                                      const SizedBox(width: 12),
                                      if (widget.questions.isNotEmpty)
                                        _buildInfoChip(
                                          icon: Icons.quiz_rounded,
                                          text:
                                              '${widget.questions.length} questions',
                                        ),
                                    ],
                                  ),
                                ] else ...[
                                  // Collapsed title for scrolled state
                                  Text(
                                    widget.title.length > 30
                                        ? '${widget.title.substring(0, 27)}...'
                                        : widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        key: ValueKey(_isBookmarked),
                        color: _isBookmarked ? widget.color : Colors.white,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isBookmarked = !_isBookmarked);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Implement share functionality
                    },
                  ),
                ],
              ),

              // Content section
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _contentAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - _contentAnimation.value)),
                      child: Opacity(
                        opacity: _contentAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRichContent(widget.content),
                              const SizedBox(height: 32),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Reading progress indicator
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  minHeight: 3,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichContent(String content) {
    final paragraphs = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value.trim();

        if (paragraph.isEmpty) return const SizedBox.shrink();

        final isHeader = _isHeaderParagraph(paragraph);
        final isBulletPoint = paragraph.startsWith('⦁');

        return Container(
          margin: EdgeInsets.only(
            bottom: isHeader ? 20 : 16,
            top: index == 0 ? 0 : (isHeader ? 24 : 0),
          ),
          child: isHeader
              ? _buildHeaderText(paragraph)
              : isBulletPoint
              ? _buildBulletPoint(paragraph)
              : _buildParagraphText(paragraph),
        );
      }).toList(),
    );
  }

  bool _isHeaderParagraph(String paragraph) {
    return paragraph.length < 100 &&
        (paragraph.contains('How ') ||
            paragraph.contains('What ') ||
            paragraph.contains('Why ') ||
            paragraph.endsWith('?'));
  }

  Widget _buildHeaderText(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: widget.color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    final cleanText = text.replaceFirst('⦁', '').trim();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              cleanText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        height: 1.6,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.questions.isNotEmpty ? _startQuiz : null,
            icon: const Icon(Icons.quiz_rounded),
            label: Text(
              widget.questions.isNotEmpty
                  ? "Take Quiz (${widget.questions.length} questions)"
                  : "No Quiz Available",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.questions.isNotEmpty
                  ? widget.color
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: widget.questions.isNotEmpty ? 4 : 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isBookmarked = !_isBookmarked);
                },
                icon: Icon(
                  _isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 18,
                ),
                label: Text(_isBookmarked ? 'Bookmarked' : 'Bookmark'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Share lesson
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Legacy support - keeping the old class name but using the new implementation
class LessonDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final List<Map<String, Object>> questions;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return ImmersiveLessonDetailScreen(
      title: title,
      content: content,
      color: color,
      questions: questions,
    );
  }
}
