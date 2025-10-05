import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';
import '../screens/admin_dashboard.dart';

class AdminAccessWidget extends StatefulWidget {
  final Color themeColor;

  const AdminAccessWidget({super.key, this.themeColor = Colors.indigo});

  @override
  State<AdminAccessWidget> createState() => _AdminAccessWidgetState();
}

class _AdminAccessWidgetState extends State<AdminAccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAdmin = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _checkAdminStatus();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isChecking = false;
      });

      if (isAdmin) {
        _controller.forward();
      }
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SizedBox.shrink(); // Don't show anything while checking
    }

    if (!_isAdmin) {
      return const SizedBox.shrink(); // Don't show for non-admin users
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.themeColor.withOpacity(0.3),
                  widget.themeColor.withOpacity(0.1),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.themeColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _navigateToAdminDashboard,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: widget.themeColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage users, review reports & system analytics',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: widget.themeColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAdminDashboard() {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AdminDashboard(themeColor: widget.themeColor),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
