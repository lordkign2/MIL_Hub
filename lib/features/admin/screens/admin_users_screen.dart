import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminUsersScreen extends StatefulWidget {
  final Color themeColor;

  const AdminUsersScreen({super.key, this.themeColor = Colors.indigo});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String? _selectedRole;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final response = await AdminService.getUsers(
        page: _currentPage,
        limit: _pageSize,
        role: _selectedRole,
        status: _selectedStatus,
      );
      setState(() {
        _users = response.users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        title: const Text('Manage Users'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            return _buildUserTile(_users[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String?>(
              value: _selectedRole,
              hint: const Text(
                'All Roles',
                style: TextStyle(color: Colors.white70),
              ),
              dropdownColor: Colors.grey[900],
              items: [
                const DropdownMenuItem(value: null, child: Text('All Roles')),
                ...UserRole.values.map(
                  (role) => DropdownMenuItem(
                    value: role.value,
                    child: Text(role.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRole = value);
                _loadUsers();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String?>(
              value: _selectedStatus,
              hint: const Text(
                'All Status',
                style: TextStyle(color: Colors.white70),
              ),
              dropdownColor: Colors.grey[900],
              items: [
                const DropdownMenuItem(value: null, child: Text('All Status')),
                ...UserStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status.value,
                    child: Text(status.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _loadUsers();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(AdminUser user) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.themeColor,
          child: Text(
            (user.displayName ?? 'U').substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.displayName ?? 'Unknown User',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'No email',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Row(
              children: [
                _buildRoleBadge(user.role),
                const SizedBox(width: 8),
                _buildStatusBadge(user.status),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.grey[800],
          onSelected: (action) => _handleUserAction(user, action),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit User')),
            const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
            const PopupMenuItem(value: 'ban', child: Text('Ban User')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'educator':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(AdminUser user, String action) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'suspend':
        _updateUserStatus(user, 'suspended');
        break;
      case 'ban':
        _updateUserStatus(user, 'banned');
        break;
    }
  }

  void _showEditUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Edit User: ${user.displayName}'),
        content: const Text('User editing functionality would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserStatus(AdminUser user, String newStatus) async {
    try {
      final success = await AdminService.updateUser(
        userId: user.id,
        status: newStatus,
        reason: 'Updated via admin panel',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.displayName} updated successfully'),
          ),
        );
        _loadUsers(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }
}
