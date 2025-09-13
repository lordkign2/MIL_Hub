import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/offline_learning_service.dart';
import '../services/hybrid_learning_service.dart';
import '../models/enhanced_lesson_model.dart';

class OfflineModeScreen extends StatefulWidget {
  final Color themeColor;

  const OfflineModeScreen({super.key, this.themeColor = Colors.blue});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  OfflineStorageInfo? _storageInfo;
  List<EnhancedLesson> _availableLessons = [];
  List<EnhancedLesson> _downloadedLessons = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadData() async {
    try {
      final storageInfo = HybridLearningService.getOfflineStorageInfo();
      final available = await HybridLearningService.searchLessons(
        '',
        limit: 50,
      );
      final downloaded = await OfflineLearningService.getCachedLessons();

      setState(() {
        _storageInfo = storageInfo;
        _availableLessons = available;
        _downloadedLessons = downloaded;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: widget.themeColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildConnectivityStatus(),
          _buildStorageOverview(),
          _buildSyncSection(),
          _buildDownloadedLessons(),
          _buildAvailableForDownload(),
          _buildStorageManagement(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.themeColor, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showOfflineSettings,
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildConnectivityStatus() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HybridLearningService.isOnline
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: HybridLearningService.isOnline
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      HybridLearningService.isOnline
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      color: HybridLearningService.isOnline
                          ? Colors.green
                          : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            HybridLearningService.isOnline
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              color: HybridLearningService.isOnline
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            HybridLearningService.isOnline
                                ? 'Connected to internet'
                                : 'Using offline content',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (HybridLearningService.lastSyncTime != null)
                      Text(
                        'Last sync: ${_formatTime(HybridLearningService.lastSyncTime!)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStorageOverview() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Overview',
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
                          child: _buildStorageCard(
                            'Lessons Cached',
                            '${_storageInfo?.totalCachedLessons ?? 0}',
                            Icons.book_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStorageCard(
                            'Downloaded',
                            '${_storageInfo?.downloadedLessons ?? 0}',
                            Icons.download_done_rounded,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStorageCard(
                            'Pending Sync',
                            '${_storageInfo?.pendingSyncItems ?? 0}',
                            Icons.sync_problem_rounded,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStorageCard(
                            'Media Files',
                            '${_storageInfo?.mediaAssets ?? 0}',
                            Icons.perm_media_rounded,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStorageCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync_rounded, color: widget.themeColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Synchronization',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if ((_storageInfo?.pendingSyncItems ?? 0) > 0) ...[
                      Text(
                        'You have ${_storageInfo!.pendingSyncItems} items waiting to sync.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: HybridLearningService.isOnline && !_isSyncing
                            ? _performSync
                            : null,
                        icon: _isSyncing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    if (!HybridLearningService.isOnline)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Connect to internet to sync your progress',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadedLessons() {
    if (_downloadedLessons.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Downloaded Lessons',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_downloadedLessons.length} lessons',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _downloadedLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _downloadedLessons[index];
                          return _buildLessonCard(lesson, isDownloaded: true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableForDownload() {
    final availableForDownload = _availableLessons
        .where(
          (lesson) => !_downloadedLessons.any(
            (downloaded) => downloaded.id == lesson.id,
          ),
        )
        .toList();

    if (availableForDownload.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 60 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Available for Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (HybridLearningService.isOnline)
                          TextButton(
                            onPressed: _downloadAll,
                            child: Text(
                              'Download All',
                              style: TextStyle(color: widget.themeColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableForDownload.length,
                        itemBuilder: (context, index) {
                          final lesson = availableForDownload[index];
                          return _buildLessonCard(lesson, isDownloaded: false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(EnhancedLesson lesson, {required bool isDownloaded}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.themeColor.withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.estimatedDuration} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                if (!isDownloaded && HybridLearningService.isOnline)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _downloadLesson(lesson),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text(
                        'Download',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isDownloaded)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download_done_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageManagement() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 70 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage_rounded, color: widget.themeColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Storage Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.cleaning_services_rounded,
                        color: Colors.orange,
                      ),
                      title: const Text(
                        'Clear Expired Cache',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Remove cached content older than 7 days',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      onTap: _clearExpiredCache,
                    ),

                    const Divider(color: Colors.white24),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Clear All Offline Data',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Remove all cached lessons and progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      onTap: _clearAllData,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action methods
  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    try {
      await HybridLearningService.syncOfflineData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _downloadLesson(EnhancedLesson lesson) async {
    try {
      await HybridLearningService.downloadLessonForOffline(lesson.id);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lesson.title} downloaded for offline use'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAll() async {
    // Implementation for downloading all available lessons
    // This would be a batch operation with progress indication
  }

  Future<void> _clearExpiredCache() async {
    try {
      await HybridLearningService.clearOfflineCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expired cache cleared'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear All Data',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all offline lessons and unsyncced progress. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HybridLearningService.clearAllOfflineData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All offline data cleared'),
              backgroundColor: Colors.green,
            ),
          );

          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showOfflineSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Offline Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Auto Download Featured',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically download featured lessons',
                style: TextStyle(color: Colors.white70),
              ),
              value: true,
              onChanged: (value) {},
              activeColor: widget.themeColor,
            ),
            SwitchListTile(
              title: const Text(
                'WiFi Only Downloads',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Only download content on WiFi',
                style: TextStyle(color: Colors.white70),
              ),
              value: true,
              onChanged: (value) {},
              activeColor: widget.themeColor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: widget.themeColor)),
          ),
        ],
      ),
    );
  }
}
