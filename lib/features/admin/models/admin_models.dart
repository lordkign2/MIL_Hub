import 'package:cloud_firestore/cloud_firestore.dart';

// System Statistics Model
class SystemStats {
  final int totalUsers;
  final int totalPosts;
  final int pendingReports;
  final Map<String, int> roleDistribution;
  final RecentActivity recentActivity;
  final SystemHealth systemHealth;

  SystemStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.pendingReports,
    required this.roleDistribution,
    required this.recentActivity,
    required this.systemHealth,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
      roleDistribution: Map<String, int>.from(json['roleDistribution'] ?? {}),
      recentActivity: RecentActivity.fromJson(json['recentActivity'] ?? {}),
      systemHealth: SystemHealth.fromJson(json['systemHealth'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalPosts': totalPosts,
      'pendingReports': pendingReports,
      'roleDistribution': roleDistribution,
      'recentActivity': recentActivity.toJson(),
      'systemHealth': systemHealth.toJson(),
    };
  }
}

class RecentActivity {
  final int newUsers;
  final int newPosts;

  RecentActivity({required this.newUsers, required this.newPosts});

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      newUsers: json['newUsers'] ?? 0,
      newPosts: json['newPosts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'newUsers': newUsers, 'newPosts': newPosts};
  }
}

class SystemHealth {
  final String status;
  final double uptime;
  final String timestamp;

  SystemHealth({
    required this.status,
    required this.uptime,
    required this.timestamp,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      status: json['status'] ?? 'unknown',
      uptime: (json['uptime'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'uptime': uptime, 'timestamp': timestamp};
  }
}

// User List Response Model
class UserListResponse {
  final List<AdminUser> users;
  final Pagination pagination;

  UserListResponse({required this.users, required this.pagination});

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      users: (json['users'] as List<dynamic>)
          .map((item) => AdminUser.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class AdminUser {
  final String id;
  final String? displayName;
  final String? email;
  final String role;
  final String status;
  final DateTime? joinedDate;
  final DateTime? lastActiveDate;
  final Map<String, dynamic>? stats;

  AdminUser({
    required this.id,
    this.displayName,
    this.email,
    required this.role,
    required this.status,
    this.joinedDate,
    this.lastActiveDate,
    this.stats,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      displayName: json['displayName'],
      email: json['email'],
      role: json['role'] ?? 'student',
      status: json['status'] ?? 'active',
      joinedDate: json['joinedDate'] != null
          ? (json['joinedDate'] as Timestamp).toDate()
          : null,
      lastActiveDate: json['lastActiveDate'] != null
          ? (json['lastActiveDate'] as Timestamp).toDate()
          : null,
      stats: json['stats'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'role': role,
      'status': status,
      'joinedDate': joinedDate != null ? Timestamp.fromDate(joinedDate!) : null,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'stats': stats,
    };
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'page': page, 'limit': limit, 'total': total, 'pages': pages};
  }
}

// Report Model
class Report {
  final String id;
  final String contentId;
  final String contentType;
  final String reportedBy;
  final String reason;
  final String? description;
  final DateTime? reportedAt;
  final String status;
  final String? reporterName;
  final ContentData? contentData;

  Report({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.reportedBy,
    required this.reason,
    this.description,
    this.reportedAt,
    required this.status,
    this.reporterName,
    this.contentData,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      contentId: json['contentId'] ?? '',
      contentType: json['contentType'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      reportedAt: json['reportedAt'] != null
          ? (json['reportedAt'] as Timestamp).toDate()
          : null,
      status: json['status'] ?? 'pending',
      reporterName: json['reporterName'],
      contentData: json['contentData'] != null
          ? ContentData.fromJson(json['contentData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'contentType': contentType,
      'reportedBy': reportedBy,
      'reason': reason,
      'description': description,
      'reportedAt': reportedAt != null ? Timestamp.fromDate(reportedAt!) : null,
      'status': status,
      'reporterName': reporterName,
      'contentData': contentData?.toJson(),
    };
  }
}

class ContentData {
  final String content;
  final String authorId;
  final DateTime? createdAt;
  final String? postId; // For comments

  ContentData({
    required this.content,
    required this.authorId,
    this.createdAt,
    this.postId,
  });

  factory ContentData.fromJson(Map<String, dynamic> json) {
    return ContentData(
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      postId: json['postId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'authorId': authorId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'postId': postId,
    };
  }
}

// Community Statistics Model
class CommunityStats {
  final String period;
  final int totalUsers;
  final int activeUsers;
  final int totalPosts;
  final int totalComments;
  final double engagementRate;

  CommunityStats({
    required this.period,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPosts,
    required this.totalComments,
    required this.engagementRate,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      period: json['period'] ?? '7d',
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalPosts': totalPosts,
      'totalComments': totalComments,
      'engagementRate': engagementRate,
    };
  }
}

// Admin Log Model
class AdminLog {
  final String id;
  final String adminId;
  final String action;
  final String? targetUserId;
  final String? reportId;
  final Map<String, dynamic>? changes;
  final String resolution;
  final String reason;
  final DateTime? timestamp;
  final String adminName;

  AdminLog({
    required this.id,
    required this.adminId,
    required this.action,
    this.targetUserId,
    this.reportId,
    this.changes,
    required this.resolution,
    required this.reason,
    this.timestamp,
    required this.adminName,
  });

  factory AdminLog.fromJson(Map<String, dynamic> json) {
    return AdminLog(
      id: json['id'] ?? '',
      adminId: json['adminId'] ?? '',
      action: json['action'] ?? '',
      targetUserId: json['targetUserId'],
      reportId: json['reportId'],
      changes: json['changes'],
      resolution: json['resolution'] ?? '',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      adminName: json['adminName'] ?? 'Unknown Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'action': action,
      'targetUserId': targetUserId,
      'reportId': reportId,
      'changes': changes,
      'resolution': resolution,
      'reason': reason,
      'timestamp': timestamp?.toIso8601String(),
      'adminName': adminName,
    };
  }
}

// Enums for admin operations
enum UserRole { student, educator, admin, moderator }

enum UserStatus { active, suspended, banned, pending }

enum ReportStatus { pending, approved, rejected, dismissed }

enum AdminAction { userUpdate, reportResolved, contentModerated, systemUpdate }

// Extension methods for enums
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.educator:
        return 'Educator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.banned:
        return 'Banned';
      case UserStatus.pending:
        return 'Pending';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}
