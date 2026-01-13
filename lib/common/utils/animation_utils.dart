// Animation Utilities for MIL Hub
// Provides helper methods for consistent and optimized animations

import 'package:flutter/material.dart';

class AnimationUtils {
  // Standard animation durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration slowDuration = Duration(milliseconds: 600);

  // Standard animation curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;

  // Fade animation
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }

  // Scale animation
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    double scaleBegin = 0.8,
    double scaleEnd = 1.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: scaleBegin,
        end: scaleEnd,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  // Slide animation
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  // Combined fade and scale animation
  static Widget fadeScaleTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    double scaleBegin = 0.8,
    double scaleEnd = 1.0,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: scaleBegin,
          end: scaleEnd,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: child,
      ),
    );
  }

  // Combined fade and slide animation
  static Widget fadeSlideTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    Offset slideBegin = const Offset(0.0, 0.2),
    Offset slideEnd = Offset.zero,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: slideBegin,
          end: slideEnd,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: child,
      ),
    );
  }

  // Staggered animation helper
  static Animation<double> createStaggeredAnimation({
    required AnimationController controller,
    required double begin,
    required double end,
    Curve curve = standardCurve,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: curve),
      ),
    );
  }

  // Optimized animation controller
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration duration = mediumDuration,
    bool useLowPowerMode = false,
  }) {
    // In low power mode, use longer durations to reduce CPU usage
    final actualDuration = useLowPowerMode
        ? Duration(milliseconds: (duration.inMilliseconds * 1.5).toInt())
        : duration;

    return AnimationController(duration: actualDuration, vsync: vsync);
  }

  // Smooth performance animation settings
  static const AnimationSettings smoothSettings = AnimationSettings(
    duration: mediumDuration,
    curve: standardCurve,
    allowHardwareAcceleration: true,
  );

  // Performance optimized animation settings
  static const AnimationSettings performanceSettings = AnimationSettings(
    duration: fastDuration,
    curve: standardCurve,
    allowHardwareAcceleration: true,
  );

  // Decorative animation settings (for non-critical animations)
  static const AnimationSettings decorativeSettings = AnimationSettings(
    duration: slowDuration,
    curve: bounceCurve,
    allowHardwareAcceleration: false,
  );
}

// Animation settings class
class AnimationSettings {
  final Duration duration;
  final Curve curve;
  final bool allowHardwareAcceleration;

  const AnimationSettings({
    required this.duration,
    required this.curve,
    required this.allowHardwareAcceleration,
  });
}
