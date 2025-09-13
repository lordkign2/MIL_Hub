// /features/learn/screens/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class InteractiveQuizScreen extends StatefulWidget {
  final Color color;
  final List<Map<String, Object>> questions;

  const InteractiveQuizScreen({
    super.key,
    required this.color,
    required this.questions,
  });

  @override
  State<InteractiveQuizScreen> createState() => _InteractiveQuizScreenState();
}

class _InteractiveQuizScreenState extends State<InteractiveQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _optionController;
  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late AnimationController _celebrationController;

  late Animation<double> _cardAnimation;
  late Animation<double> _optionAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _feedbackAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOption;
  bool _showFeedback = false;
  bool _isCorrect = false;

  // Adaptive learning variables
  List<int> _timeSpentPerQuestion = [];
  List<bool> _correctAnswers = [];
  DateTime? _questionStartTime;
  double _difficultyRating = 1.0;

  // Animation states
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startQuestion();
  }

  void _initializeAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _optionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _optionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _optionController, curve: Curves.easeOutBack),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
  }

  void _startQuestion() {
    _questionStartTime = DateTime.now();
    _cardController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _optionController.forward();
    });

    _progressController.animateTo(
      (_currentIndex + 1) / widget.questions.length,
    );
  }

  void _checkAnswer(int selected) {
    if (_answered || _isTransitioning) return;

    setState(() {
      _answered = true;
      _selectedOption = selected;
      _isCorrect = selected == widget.questions[_currentIndex]["answer"];
      _showFeedback = true;
    });

    // Record time spent
    if (_questionStartTime != null) {
      final timeSpent = DateTime.now()
          .difference(_questionStartTime!)
          .inSeconds;
      _timeSpentPerQuestion.add(timeSpent);
    }

    // Record correctness
    _correctAnswers.add(_isCorrect);

    // Update score and difficulty
    if (_isCorrect) {
      _score++;
      _celebrationController.forward().then((_) {
        _celebrationController.reset();
      });
    }

    // Show feedback animation
    _feedbackController.forward();

    // Haptic feedback
    if (_isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Update adaptive difficulty
    _updateDifficultyRating();
  }

  void _updateDifficultyRating() {
    if (_timeSpentPerQuestion.isNotEmpty) {
      final avgTime =
          _timeSpentPerQuestion.reduce((a, b) => a + b) /
          _timeSpentPerQuestion.length;
      final accuracy =
          _correctAnswers.where((correct) => correct).length /
          _correctAnswers.length;

      // Adjust difficulty based on performance
      if (accuracy > 0.8 && avgTime < 15) {
        _difficultyRating = math.min(_difficultyRating + 0.2, 2.0);
      } else if (accuracy < 0.5 || avgTime > 30) {
        _difficultyRating = math.max(_difficultyRating - 0.2, 0.5);
      }
    }
  }

  void _nextQuestion() {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);

    // Reset animations
    _feedbackController.reverse().then((_) {
      _cardController.reverse().then((_) {
        if (_currentIndex < widget.questions.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
            _selectedOption = null;
            _showFeedback = false;
            _isTransitioning = false;
          });

          _cardController.reset();
          _optionController.reset();
          _feedbackController.reset();

          _startQuestion();
        } else {
          _showResult();
        }
      });
    });
  }

  void _showResult() {
    final accuracy = (_score / widget.questions.length * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizResultDialog(
        score: _score,
        totalQuestions: widget.questions.length,
        accuracy: accuracy,
        timeSpent: _timeSpentPerQuestion.fold(0, (sum, time) => sum + time),
        difficultyRating: _difficultyRating,
        color: widget.color,
        onClose: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Go back to lesson
        },
        onRetry: () {
          Navigator.pop(context); // Close dialog
          _resetQuiz();
        },
      ),
    );
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedOption = null;
      _showFeedback = false;
      _isTransitioning = false;
      _timeSpentPerQuestion.clear();
      _correctAnswers.clear();
      _difficultyRating = 1.0;
    });

    _cardController.reset();
    _optionController.reset();
    _progressController.reset();
    _feedbackController.reset();

    _startQuestion();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _optionController.dispose();
    _progressController.dispose();
    _feedbackController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: widget.color,
          title: const Text("Quiz"),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "No quiz questions available for this lesson.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final question = widget.questions[_currentIndex];
    final options = question["options"] as List<String>;
    final correctAnswer = question["answer"] as int;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar with Progress
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color, widget.color.withOpacity(0.8)],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Question ${_currentIndex + 1} of ${widget.questions.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            '$_score/${widget.questions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Animated Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Question Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Question Card
                        Expanded(
                          flex: 2,
                          child: AnimatedBuilder(
                            animation: _cardAnimation,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _cardAnimation,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: widget.color.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.quiz_rounded,
                                          color: widget.color,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          question["question"] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Options
                        Expanded(
                          flex: 3,
                          child: AnimatedBuilder(
                            animation: _optionAnimation,
                            builder: (context, child) {
                              return Column(
                                children: List.generate(options.length, (
                                  index,
                                ) {
                                  final delay = index * 0.1;
                                  final animationValue =
                                      (_optionAnimation.value - delay).clamp(
                                        0.0,
                                        1.0,
                                      );

                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      30 * (1 - animationValue),
                                    ),
                                    child: Opacity(
                                      opacity: animationValue,
                                      child: _buildOptionCard(
                                        option: options[index],
                                        index: index,
                                        correctAnswer: correctAnswer,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),

                        // Feedback Section
                        if (_showFeedback)
                          AnimatedBuilder(
                            animation: _feedbackAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _feedbackAnimation.value,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(top: 20),
                                  decoration: BoxDecoration(
                                    color: _isCorrect
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isCorrect
                                          ? Colors.green
                                          : Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _isCorrect
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        color: _isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isCorrect
                                            ? 'Correct! Well done!'
                                            : 'Incorrect. Try again next time!',
                                        style: TextStyle(
                                          color: _isCorrect
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (!_isCorrect)
                                        const SizedBox(height: 8),
                                      if (!_isCorrect)
                                        Text(
                                          'The correct answer was: ${options[correctAnswer]}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // Next Button
                        if (_answered && !_isTransitioning)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _currentIndex < widget.questions.length - 1
                                    ? "Next Question"
                                    : "Finish Quiz",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Celebration overlay
          if (_isCorrect && _celebrationAnimation.value > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CelebrationPainter(
                        animation: _celebrationAnimation.value,
                        color: widget.color,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required int index,
    required int correctAnswer,
  }) {
    bool isSelected = _selectedOption == index;
    bool isCorrect = index == correctAnswer;
    bool showResult = _answered;

    Color getBackgroundColor() {
      if (!showResult) {
        return isSelected
            ? widget.color.withOpacity(0.2)
            : Colors.white.withOpacity(0.05);
      }

      if (isCorrect) {
        return Colors.green.withOpacity(0.2);
      } else if (isSelected && !isCorrect) {
        return Colors.red.withOpacity(0.2);
      } else {
        return Colors.white.withOpacity(0.05);
      }
    }

    Color getBorderColor() {
      if (!showResult) {
        return isSelected ? widget.color : Colors.white.withOpacity(0.2);
      }

      if (isCorrect) {
        return Colors.green;
      } else if (isSelected && !isCorrect) {
        return Colors.red;
      } else {
        return Colors.white.withOpacity(0.2);
      }
    }

    IconData? getIcon() {
      if (!showResult) return null;

      if (isCorrect) {
        return Icons.check_circle_rounded;
      } else if (isSelected && !isCorrect) {
        return Icons.cancel_rounded;
      }

      return null;
    }

    Color? getIconColor() {
      if (!showResult) return null;

      if (isCorrect) {
        return Colors.green;
      } else if (isSelected && !isCorrect) {
        return Colors.red;
      }

      return null;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _checkAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: getBorderColor(), width: 2),
            ),
            child: Row(
              children: [
                // Option letter
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getBorderColor().withOpacity(0.2),
                    border: Border.all(color: getBorderColor(), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        color: getBorderColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Result icon
                if (getIcon() != null) const SizedBox(width: 12),
                if (getIcon() != null)
                  Icon(getIcon(), color: getIconColor(), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Celebration Painter
class CelebrationPainter extends CustomPainter {
  final double animation;
  final Color color;

  CelebrationPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8 * (1 - animation))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * animation * 0.8;

    // Draw expanding circle
    canvas.drawCircle(center, radius, paint);

    // Draw particles
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * (1 - animation))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180);
      final particleRadius = 4.0 * animation;
      final distance = 100 * animation;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      canvas.drawCircle(Offset(x, y), particleRadius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Quiz Result Dialog
class QuizResultDialog extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int accuracy;
  final int timeSpent;
  final double difficultyRating;
  final Color color;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  const QuizResultDialog({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.accuracy,
    required this.timeSpent,
    required this.difficultyRating,
    required this.color,
    required this.onClose,
    required this.onRetry,
  });

  @override
  State<QuizResultDialog> createState() => _QuizResultDialogState();
}

class _QuizResultDialogState extends State<QuizResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get performanceMessage {
    if (widget.accuracy >= 90) return "Excellent! Outstanding performance!";
    if (widget.accuracy >= 80) return "Great job! Well done!";
    if (widget.accuracy >= 70) return "Good work! Keep it up!";
    if (widget.accuracy >= 60) return "Not bad! Room for improvement.";
    return "Keep practicing! You'll get better!";
  }

  IconData get performanceIcon {
    if (widget.accuracy >= 90) return Icons.emoji_events_rounded;
    if (widget.accuracy >= 80) return Icons.celebration_rounded;
    if (widget.accuracy >= 70) return Icons.thumb_up_rounded;
    if (widget.accuracy >= 60) return Icons.trending_up_rounded;
    return Icons.refresh_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Performance Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.6)],
                      ),
                    ),
                    child: Icon(performanceIcon, color: Colors.white, size: 40),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Quiz Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Performance Message
                  Text(
                    performanceMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Statistics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Score',
                          '${widget.score}/${widget.totalQuestions}',
                        ),
                        _buildStatRow('Accuracy', '${widget.accuracy}%'),
                        _buildStatRow('Time Spent', '${widget.timeSpent}s'),
                        _buildStatRow(
                          'Difficulty',
                          '${(widget.difficultyRating * 100).round()}%',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onRetry,
                          child: Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: widget.color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy support - keeping the old class name but using the new implementation
class QuizScreen extends StatelessWidget {
  final Color color;
  final List<Map<String, Object>> questions;

  const QuizScreen({super.key, required this.color, required this.questions});

  @override
  Widget build(BuildContext context) {
    return InteractiveQuizScreen(color: color, questions: questions);
  }
}
