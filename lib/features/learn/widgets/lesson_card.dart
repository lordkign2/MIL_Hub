import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lesson_model.dart';
import '../screens/lesson_detail_screen.dart';

class ElegantLessonCard extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  
  const ElegantLessonCard({
    super.key, 
    required this.lesson,
    this.onBookmark,
    this.onShare,
  });

  @override
  State<ElegantLessonCard> createState() => _ElegantLessonCardState();
}

class _ElegantLessonCardState extends State<ElegantLessonCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isHovered = false;
  bool _isBookmarked = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.lesson.progress / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _mapIcon(String iconName) {
    switch (iconName) {
      case "visibility":
        return Icons.visibility_rounded;
      case "shield":
        return Icons.shield_rounded;
      case "balance":
        return Icons.balance_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  String _getDifficultyText() {
    final progress = widget.lesson.progress;
    if (progress < 25) return "Beginner";
    if (progress < 50) return "Intermediate";
    if (progress < 75) return "Advanced";
    return "Expert";
  }

  Color _getDifficultyColor() {
    final progress = widget.lesson.progress;
    if (progress < 25) return Colors.green;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.red;
    return Colors.purple;
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    
    if (widget.lesson.title.isNotEmpty && widget.lesson.content.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LessonDetailScreen(
                title: widget.lesson.title,
                content: widget.lesson.content,
                color: widget.lesson.color ?? Colors.purple,
                questions: widget.lesson.questionsAsMap,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.lesson.color ?? Colors.purple;
    final bool isCompleted = widget.lesson.progress >= 100;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _elevationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              shadowColor: themeColor.withOpacity(0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _handleTap,
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                },
                onHover: (hovering) {
                  setState(() => _isHovered = hovering);
                  if (hovering) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withOpacity(_isPressed ? 0.3 : 0.15),
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                    border: Border.all(
                      color: _isHovered 
                          ? themeColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: _isHovered ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Icon with Hero animation and pulse effect
                            Hero(
                              tag: "lesson_icon_${widget.lesson.title}",
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: isCompleted ? _pulseAnimation.value : 1.0,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            themeColor.withOpacity(0.8),
                                            themeColor.withOpacity(0.4),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _mapIcon(widget.lesson.icon),
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title with gradient effect
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        themeColor.withOpacity(0.8),
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      widget.lesson.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 6),
                                  
                                  // Subtitle
                                  Text(
                                    widget.lesson.subtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action buttons
                            Column(
                              children: [
                                // Bookmark button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isBookmarked = !_isBookmarked);
                                    widget.onBookmark?.call();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isBookmarked
                                          ? themeColor.withOpacity(0.2)
                                          : Colors.transparent,
                                    ),
                                    child: Icon(
                                      _isBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: _isBookmarked ? themeColor : Colors.white54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // More options
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showMoreOptions(context, themeColor);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Progress section
                        Row(
                          children: [
                            // Difficulty badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getDifficultyColor().withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                _getDifficultyText(),
                                style: TextStyle(
                                  color: _getDifficultyColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Questions count
                            if (widget.lesson.questions.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.quiz_rounded,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${widget.lesson.questions.length} Quiz",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const Spacer(),
                            
                            // Progress percentage
                            Text(
                              "${widget.lesson.progress.toInt()}%",
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Animated progress bar
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Stack(
                                children: [
                                  // Background
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  
                                  // Progress fill with gradient
                                  FractionallySizedBox(
                                    widthFactor: _progressAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: LinearGradient(
                                          colors: [
                                            themeColor,
                                            themeColor.withOpacity(0.6),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeColor.withOpacity(0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Shine effect
                                  if (_progressAnimation.value > 0)
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 20,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.0),
                                              Colors.white.withOpacity(0.3),
                                              Colors.white.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.share_rounded, color: themeColor),
              title: const Text(
                "Share Lesson",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onShare?.call();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.download_rounded, color: themeColor),
              title: const Text(
                "Download for Offline",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement offline download
              },
            ),
            
            ListTile(
              leading: Icon(Icons.report_rounded, color: Colors.orange),
              title: const Text(
                "Report Issue",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement reporting
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Legacy support - keeping the old class name but using the new implementation
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return ElegantLessonCard(lesson: lesson);
  }
}
