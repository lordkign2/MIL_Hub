import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/admin_models.dart';

class AdminService {
  static const String _baseUrl = 'http://localhost:5000';
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // This would typically check user role from Firestore
      // For now, we'll check if they can access admin stats
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get system statistics
  static Future<SystemStats> getSystemStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SystemStats.fromJson(data);
      } else {
        throw Exception('Failed to load system stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching system stats: $e');
    }
  }

  // Get users with pagination
  static Future<UserListResponse> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      };

      final uri = Uri.parse(
        '$_baseUrl/admin/users',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Update user role or status
  static Future<bool> updateUser({
    required String userId,
    String? role,
    String? status,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (role != null) body['role'] = role;
      if (status != null) body['status'] = status;
      if (reason != null) body['reason'] = reason;

      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Get reported content
  static Future<List<Report>> getReports({
    String status = 'pending',
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/admin/reports',
      ).replace(queryParameters: {'status': status, 'limit': limit.toString()});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Report.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  // Handle report (approve/reject/dismiss)
  static Future<bool> handleReport({
    required String reportId,
    required String action, // 'approve', 'reject', 'dismiss'
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/reports/$reportId'),
        headers: await _getHeaders(),
        body: json.encode({
          'action': action,
          if (reason != null) 'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error handling report: $e');
    }
  }

  // Get community analytics
  static Future<CommunityStats> getCommunityStats({
    String period = '7d',
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/admin/community-stats',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunityStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load community stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching community stats: $e');
    }
  }

  // Get admin action logs
  static Future<List<AdminLog>> getAdminLogs({int limit = 50}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/admin/logs',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AdminLog.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load admin logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching admin logs: $e');
    }
  }

  // Batch operations
  static Future<bool> batchUpdateUsers({
    required List<String> userIds,
    String? role,
    String? status,
    String? reason,
  }) async {
    try {
      // For simplicity, we'll process these sequentially
      // In production, you'd want a dedicated batch endpoint
      for (final userId in userIds) {
        final success = await updateUser(
          userId: userId,
          role: role,
          status: status,
          reason: reason,
        );
        if (!success) return false;
      }
      return true;
    } catch (e) {
      throw Exception('Error in batch update: $e');
    }
  }

  // Export data (placeholder - would generate CSV/JSON export)
  static Future<String> exportData({
    required String dataType, // 'users', 'posts', 'reports'
    Map<String, dynamic>? filters,
  }) async {
    try {
      // In a real implementation, this would generate and return a download URL
      // For now, we'll return a success message
      return 'Export initiated for $dataType. Download link will be sent via email.';
    } catch (e) {
      throw Exception('Error initiating export: $e');
    }
  }
}
