import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminLogsScreen extends StatefulWidget {
  final Color themeColor;

  const AdminLogsScreen({super.key, this.themeColor = Colors.indigo});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  List<AdminLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() => _isLoading = true);
      final logs = await AdminService.getAdminLogs(limit: 100);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        title: const Text('Admin Activity Logs'),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadLogs, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(
              child: Text(
                'No admin logs found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return _buildLogTile(_logs[index]);
              },
            ),
    );
  }

  Widget _buildLogTile(AdminLog log) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(log.action),
          child: Icon(
            _getActionIcon(log.action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getActionTitle(log.action),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By: ${log.adminName}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (log.timestamp != null)
              Text(
                _formatDateTime(log.timestamp!),
                style: TextStyle(color: Colors.grey[500]),
              ),
            if (log.reason.isNotEmpty)
              Text(
                'Reason: ${log.reason}',
                style: TextStyle(color: Colors.grey[400]),
              ),
          ],
        ),
        trailing: log.changes != null
            ? IconButton(
                onPressed: () => _showDetailsDialog(log),
                icon: const Icon(Icons.info_outline, color: Colors.white70),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'user_update':
        return Colors.blue;
      case 'report_resolved':
        return Colors.green;
      case 'content_moderated':
        return Colors.red;
      case 'system_update':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'user_update':
        return Icons.person_outline;
      case 'report_resolved':
        return Icons.check_circle_outline;
      case 'content_moderated':
        return Icons.remove_moderator;
      case 'system_update':
        return Icons.settings;
      default:
        return Icons.info_outline;
    }
  }

  String _getActionTitle(String action) {
    switch (action.toLowerCase()) {
      case 'user_update':
        return 'User Updated';
      case 'report_resolved':
        return 'Report Resolved';
      case 'content_moderated':
        return 'Content Moderated';
      case 'system_update':
        return 'System Updated';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailsDialog(AdminLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Log Details: ${_getActionTitle(log.action)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Admin', log.adminName),
              _buildDetailRow('Action', log.action),
              if (log.timestamp != null)
                _buildDetailRow('Timestamp', _formatDateTime(log.timestamp!)),
              if (log.targetUserId != null)
                _buildDetailRow('Target User ID', log.targetUserId!),
              if (log.reportId != null)
                _buildDetailRow('Report ID', log.reportId!),
              if (log.reason.isNotEmpty) _buildDetailRow('Reason', log.reason),
              if (log.resolution.isNotEmpty)
                _buildDetailRow('Resolution', log.resolution),
              if (log.changes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Changes:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.changes.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
