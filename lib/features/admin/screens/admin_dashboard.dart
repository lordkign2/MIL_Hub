import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_chart_widget.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_logs_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Color themeColor;

  const AdminDashboard({super.key, this.themeColor = Colors.indigo});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  SystemStats? _systemStats;
  CommunityStats? _communityStats;
  bool _isLoading = true;
  String _selectedPeriod = '7d';

  final List<String> _periods = ['7d', '30d', '90d'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final systemStatsFuture = AdminService.getSystemStats();
      final communityStatsFuture = AdminService.getCommunityStats(
        period: _selectedPeriod,
      );

      final results = await Future.wait([
        systemStatsFuture,
        communityStatsFuture,
      ]);

      setState(() {
        _systemStats = results[0] as SystemStats;
        _communityStats = results[1] as CommunityStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadData();
  }

  void _onPeriodChanged(String period) {
    if (period != _selectedPeriod) {
      setState(() => _selectedPeriod = period);
      _loadData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: widget.themeColor,
        backgroundColor: Colors.grey[900],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            if (_isLoading) _buildLoadingState() else _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.themeColor,
              widget.themeColor.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          background: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 80,
                  top: 100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'System Overview',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildPeriodSelector(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: _periods.map((period) {
            return DropdownMenuItem(value: period, child: Text(period));
          }).toList(),
          onChanged: (value) => value != null ? _onPeriodChanged(value) : null,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.themeColor),
            const SizedBox(height: 16),
            Text(
              'Loading admin data...',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemOverview(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildCommunityStats(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    if (_systemStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            AdminStatsCard(
              title: 'Total Users',
              value: _systemStats!.totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
              trend: '+${_systemStats!.recentActivity.newUsers}',
            ),
            AdminStatsCard(
              title: 'Total Posts',
              value: _systemStats!.totalPosts.toString(),
              icon: Icons.article,
              color: Colors.green,
              trend: '+${_systemStats!.recentActivity.newPosts}',
            ),
            AdminStatsCard(
              title: 'Pending Reports',
              value: _systemStats!.pendingReports.toString(),
              icon: Icons.report,
              color: _systemStats!.pendingReports > 0
                  ? Colors.red
                  : Colors.orange,
              onTap: () => _navigateToReports(),
            ),
            AdminStatsCard(
              title: 'System Health',
              value: _systemStats!.systemHealth.status.toUpperCase(),
              icon: Icons.health_and_safety,
              color: _systemStats!.systemHealth.status == 'healthy'
                  ? Colors.green
                  : Colors.red,
              subtitle:
                  'Uptime: ${(_systemStats!.systemHealth.uptime / 3600).toStringAsFixed(1)}h',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
              child: _buildActionButton(
                'Manage Users',
                Icons.people_alt,
                Colors.blue,
                () => _navigateToUsers(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Review Reports',
                Icons.flag,
                Colors.red,
                () => _navigateToReports(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Logs',
                Icons.history,
                Colors.orange,
                () => _navigateToLogs(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Export Data',
                Icons.download,
                Colors.purple,
                () => _showExportDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStats() {
    if (_communityStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AdminChartWidget(
          communityStats: _communityStats!,
          themeColor: widget.themeColor,
          period: _selectedPeriod,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(foregroundColor: widget.themeColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _buildStatusRow('Server Status', 'Online', Colors.green),
              const Divider(color: Colors.grey, height: 24),
              _buildStatusRow('Database', 'Connected', Colors.green),
              const Divider(color: Colors.grey, height: 24),
              _buildStatusRow('Authentication', 'Active', Colors.green),
              const Divider(color: Colors.grey, height: 24),
              _buildStatusRow(
                'Last Updated',
                _formatDateTime(DateTime.now()),
                Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUsersScreen(themeColor: widget.themeColor),
      ),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminReportsScreen(themeColor: widget.themeColor),
      ),
    );
  }

  void _navigateToLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminLogsScreen(themeColor: widget.themeColor),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Export Data', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select data to export:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildExportOption('User Data', Icons.people, () async {
              Navigator.pop(context);
              await _exportData('users');
            }),
            _buildExportOption('Community Posts', Icons.article, () async {
              Navigator.pop(context);
              await _exportData('posts');
            }),
            _buildExportOption('Reports', Icons.report, () async {
              Navigator.pop(context);
              await _exportData('reports');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: widget.themeColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _exportData(String dataType) async {
    try {
      final result = await AdminService.exportData(dataType: dataType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
