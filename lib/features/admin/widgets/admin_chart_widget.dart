import 'package:flutter/material.dart';
import '../models/admin_models.dart';

class AdminChartWidget extends StatefulWidget {
  final CommunityStats communityStats;
  final Color themeColor;
  final String period;

  const AdminChartWidget({
    super.key,
    required this.communityStats,
    required this.themeColor,
    required this.period,
  });

  @override
  State<AdminChartWidget> createState() => _AdminChartWidgetState();
}

class _AdminChartWidgetState extends State<AdminChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _controller.forward();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(AdminChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community Engagement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPeriodLabel(widget.period),
                  style: TextStyle(
                    color: widget.themeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEngagementOverview(),
          const SizedBox(height: 24),
          _buildMetricsBars(),
        ],
      ),
    );
  }

  Widget _buildEngagementOverview() {
    final engagementRate = widget.communityStats.engagementRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Rate',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${engagementRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: (engagementRate / 100) * _progressAnimation.value,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getEngagementColor(engagementRate),
                    ),
                    minHeight: 6,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getEngagementLabel(engagementRate),
          style: TextStyle(
            color: _getEngagementColor(engagementRate),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsBars() {
    final metrics = [
      {
        'label': 'Active Users',
        'value': widget.communityStats.activeUsers.toDouble(),
        'max': widget.communityStats.totalUsers.toDouble(),
        'color': Colors.blue,
      },
      {
        'label': 'Posts Created',
        'value': widget.communityStats.totalPosts.toDouble(),
        'max': widget.communityStats.totalPosts.toDouble() * 1.2,
        'color': Colors.green,
      },
      {
        'label': 'Comments',
        'value': widget.communityStats.totalComments.toDouble(),
        'max': widget.communityStats.totalComments.toDouble() * 1.2,
        'color': Colors.orange,
      },
    ];

    return Column(
      children: metrics.map((metric) {
        final percentage = metric['max'] as double > 0
            ? (metric['value'] as double) / (metric['max'] as double)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metric['label'] as String,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  Text(
                    _formatNumber((metric['value'] as double).round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: percentage * _progressAnimation.value,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      metric['color'] as Color,
                    ),
                    minHeight: 4,
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      default:
        return 'Unknown Period';
    }
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getEngagementLabel(double rate) {
    if (rate >= 70) return 'Excellent';
    if (rate >= 40) return 'Good';
    if (rate >= 20) return 'Fair';
    return 'Needs Improvement';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
