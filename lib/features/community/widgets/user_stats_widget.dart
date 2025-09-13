import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/community_service.dart';
import '../../../constants/global_variables.dart';

class UserStatsWidget extends StatelessWidget {
  final String? userId;
  final bool isCompact;

  const UserStatsWidget({super.key, this.userId, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (targetUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: CommunityService.getUserStats(targetUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingStats();
        }

        final stats = snapshot.data!;
        return isCompact ? _buildCompactStats(stats) : _buildFullStats(stats);
      },
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPlaceholder(),
          _buildStatPlaceholder(),
          _buildStatPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildStatPlaceholder() {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStats(Map<String, dynamic> stats) {
    final postsCount = stats['postsCount'] ?? 0;
    final likesReceived = stats['likesReceived'] ?? 0;
    final commentsCount = stats['commentsCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactStat(postsCount, 'Posts'),
          const SizedBox(width: 16),
          _buildCompactStat(likesReceived, 'Likes'),
          const SizedBox(width: 16),
          _buildCompactStat(commentsCount, 'Comments'),
        ],
      ),
    );
  }

  Widget _buildCompactStat(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
      ],
    );
  }

  Widget _buildFullStats(Map<String, dynamic> stats) {
    final postsCount = stats['postsCount'] ?? 0;
    final likesReceived = stats['likesReceived'] ?? 0;
    final likesGiven = stats['likesGiven'] ?? 0;
    final commentsCount = stats['commentsCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: GlobalVariables.appBarGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFullStat(postsCount, 'Posts', Icons.article),
              ),
              Expanded(
                child: _buildFullStat(
                  likesReceived,
                  'Likes Received',
                  Icons.favorite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFullStat(
                  commentsCount,
                  'Comments',
                  Icons.chat_bubble,
                ),
              ),
              Expanded(
                child: _buildFullStat(
                  likesGiven,
                  'Likes Given',
                  Icons.thumb_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEngagementRate(stats),
        ],
      ),
    );
  }

  Widget _buildFullStat(int value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            _formatNumber(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRate(Map<String, dynamic> stats) {
    final postsCount = stats['postsCount'] ?? 0;
    final likesReceived = stats['likesReceived'] ?? 0;
    final commentsReceived = stats['commentsReceived'] ?? 0;

    final totalEngagement = likesReceived + commentsReceived;
    final engagementRate = postsCount > 0
        ? (totalEngagement / postsCount)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Engagement Rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${engagementRate.toStringAsFixed(1)} per post',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getEngagementColor(engagementRate),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getEngagementLabel(engagementRate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 10) return Colors.green;
    if (rate >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getEngagementLabel(double rate) {
    if (rate >= 10) return 'HIGH';
    if (rate >= 5) return 'GOOD';
    return 'LOW';
  }

  String _formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      final k = number / 1000;
      return k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    } else {
      final m = number / 1000000;
      return m % 1 == 0 ? '${m.toInt()}m' : '${m.toStringAsFixed(1)}m';
    }
  }
}

class CommunityBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const CommunityBadgeWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final badge = _calculateBadge(stats);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: badge['gradient'] as LinearGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (badge['color'] as Color).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'] as IconData, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            badge['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateBadge(Map<String, dynamic> stats) {
    final postsCount = stats['postsCount'] ?? 0;
    final likesReceived = stats['likesReceived'] ?? 0;
    final totalEngagement = likesReceived + (stats['commentsReceived'] ?? 0);

    if (postsCount >= 100 && totalEngagement >= 1000) {
      return {
        'title': 'Community Legend',
        'icon': Icons.star,
        'color': Colors.purple,
        'gradient': const LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
        ),
      };
    } else if (postsCount >= 50 && totalEngagement >= 500) {
      return {
        'title': 'Active Contributor',
        'icon': Icons.trending_up,
        'color': Colors.orange,
        'gradient': const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
      };
    } else if (postsCount >= 20 && totalEngagement >= 100) {
      return {
        'title': 'Regular Member',
        'icon': Icons.people,
        'color': Colors.blue,
        'gradient': const LinearGradient(colors: [Colors.blue, Colors.indigo]),
      };
    } else if (postsCount >= 5) {
      return {
        'title': 'New Contributor',
        'icon': Icons.person_add,
        'color': Colors.green,
        'gradient': const LinearGradient(colors: [Colors.green, Colors.teal]),
      };
    } else {
      return {
        'title': 'New Member',
        'icon': Icons.account_circle,
        'color': Colors.grey,
        'gradient': const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
        ),
      };
    }
  }
}
