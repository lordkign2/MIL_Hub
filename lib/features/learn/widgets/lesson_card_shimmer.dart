import 'package:flutter/material.dart';

class LessonCardShimmer extends StatefulWidget {
  const LessonCardShimmer({super.key});

  @override
  State<LessonCardShimmer> createState() => _LessonCardShimmerState();
}

class _LessonCardShimmerState extends State<LessonCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(20),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[800]!.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Icon placeholder
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[700]!.withOpacity(0.3),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Content placeholders
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title placeholder
                                  Container(
                                    height: 20,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700]!.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Subtitle placeholder
                                  Container(
                                    height: 16,
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700]!.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons placeholders
                            Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[700]!.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[700]!.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Tags row placeholder
                        Row(
                          children: [
                            Container(
                              height: 24,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[700]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 24,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[700]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 16,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[700]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress bar placeholder
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[700]!.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Shimmer overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Transform.translate(
                        offset: Offset(
                          _animation.value * MediaQuery.of(context).size.width,
                          0,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LessonListShimmer extends StatelessWidget {
  final int itemCount;

  const LessonListShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => const LessonCardShimmer(),
        ),
      ),
    );
  }
}
