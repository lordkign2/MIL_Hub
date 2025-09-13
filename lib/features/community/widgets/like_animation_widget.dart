import 'package:flutter/material.dart';
import 'dart:math' as math;

class LikeAnimationWidget extends StatefulWidget {
  final Widget child;
  final bool isLiked;
  final VoidCallback onTap;
  final Duration duration;
  final double size;

  const LikeAnimationWidget({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onTap,
    this.duration = const Duration(milliseconds: 600),
    this.size = 100,
  });

  @override
  State<LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<LikeAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _burstAnimationController;
  late AnimationController _circleAnimationController;

  late Animation<double> _sizeAnimation;
  late Animation<double> _burstAnimation;
  late Animation<double> _circleAnimation;

  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main like animation
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Burst animation for particles
    _burstAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Circle animation
    _circleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Size animation with overshoot effect
    _sizeAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_animationController);

    // Burst animation for floating particles
    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _burstAnimationController, curve: Curves.easeOut),
    );

    // Circle expansion animation
    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _circleAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _burstAnimationController.dispose();
    _circleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap();

    if (widget.isLiked) {
      // Start all animations simultaneously
      setState(() {
        _showParticles = true;
      });

      _animationController.forward();
      _circleAnimationController.forward();
      _burstAnimationController.forward();

      // Hide particles after animation
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _showParticles = false;
        });
        _burstAnimationController.reset();
        _circleAnimationController.reset();
      }

      // Reset main animation
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circle expansion effect
          AnimatedBuilder(
            animation: _circleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _circleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(
                      0.3 * (1 - _circleAnimation.value),
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating particles
          if (_showParticles) ..._buildParticles(),

          // Main like button
          AnimatedBuilder(
            animation: _sizeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _sizeAnimation.value,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    const particleCount = 6;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      particles.add(_buildParticle(angle, i));
    }

    return particles;
  }

  Widget _buildParticle(double angle, int index) {
    return AnimatedBuilder(
      animation: _burstAnimation,
      builder: (context, child) {
        final distance = 40 * _burstAnimation.value;
        final x = math.cos(angle) * distance;
        final y = math.sin(angle) * distance;

        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: 1.0 - _burstAnimation.value,
            child: Opacity(
              opacity: 1.0 - _burstAnimation.value,
              child: _buildParticleShape(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleShape(int index) {
    final shapes = [
      // Heart particles
      const Icon(Icons.favorite, color: Colors.red, size: 8),
      // Star particles
      const Icon(Icons.star, color: Colors.amber, size: 8),
      // Circle particles
      Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.circle,
        ),
      ),
    ];

    return shapes[index % shapes.length];
  }
}

class LikeCounterWidget extends StatefulWidget {
  final int count;
  final bool isLiked;
  final Duration animationDuration;

  const LikeCounterWidget({
    super.key,
    required this.count,
    required this.isLiked,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LikeCounterWidget> createState() => _LikeCounterWidgetState();
}

class _LikeCounterWidgetState extends State<LikeCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int _previousCount = 0;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.count;
    _previousCount = widget.count;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LikeCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.count != widget.count) {
      setState(() {
        _previousCount = oldWidget.count;
        _currentCount = widget.count;
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Previous count (sliding out)
            if (_animationController.isAnimating &&
                _previousCount != _currentCount)
              Transform.translate(
                offset: Offset(0, -20 * _slideAnimation.value),
                child: Opacity(
                  opacity: 1.0 - _fadeAnimation.value,
                  child: Text(
                    _formatCount(_previousCount),
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isLiked ? Colors.red[400] : Colors.grey,
                    ),
                  ),
                ),
              ),

            // Current count (sliding in)
            Transform.translate(
              offset: Offset(
                0,
                _animationController.isAnimating
                    ? 20 * (1 - _slideAnimation.value)
                    : 0,
              ),
              child: Opacity(
                opacity: _animationController.isAnimating
                    ? _fadeAnimation.value
                    : 1.0,
                child: Text(
                  _formatCount(_currentCount),
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isLiked ? Colors.red[400] : Colors.grey,
                    fontWeight: widget.isLiked
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}m' : '${m.toStringAsFixed(1)}m';
    }
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;
  final double maxScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 1000),
    this.maxScale = 1.1,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.maxScale).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
