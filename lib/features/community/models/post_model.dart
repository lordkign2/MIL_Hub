import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PostType { text, image, video, poll }

enum PostPrivacy { public, friends, private }

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String? authorTitle; // User title/role in community
  final String content;
  final PostType type;
  final PostPrivacy privacy;
  final List<String>? mediaUrls;
  final Map<String, dynamic>? pollData;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;
  final bool isArchived;
  final bool isReported;
  final Map<String, dynamic>? metadata;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    this.authorTitle,
    required this.content,
    this.type = PostType.text,
    this.privacy = PostPrivacy.public,
    this.mediaUrls,
    this.pollData,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isReported = false,
    this.metadata,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhoto: data['authorPhoto'],
      authorTitle: data['authorTitle'],
      content: data['content'] ?? '',
      type: PostType.values.firstWhere(
        (type) => type.toString() == 'PostType.${data['type']}',
        orElse: () => PostType.text,
      ),
      privacy: PostPrivacy.values.firstWhere(
        (privacy) => privacy.toString() == 'PostPrivacy.${data['privacy']}',
        orElse: () => PostPrivacy.public,
      ),
      mediaUrls: data['mediaUrls'] != null
          ? List<String>.from(data['mediaUrls'])
          : null,
      pollData: data['pollData'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      likedBy: data['likedBy'] != null
          ? List<String>.from(data['likedBy'])
          : [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isPinned: data['isPinned'] ?? false,
      isArchived: data['isArchived'] ?? false,
      isReported: data['isReported'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'authorTitle': authorTitle,
      'content': content,
      'type': type.toString().split('.').last,
      'privacy': privacy.toString().split('.').last,
      'mediaUrls': mediaUrls,
      'pollData': pollData,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isReported': isReported,
      'metadata': metadata,
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    String? authorTitle,
    String? content,
    PostType? type,
    PostPrivacy? privacy,
    List<String>? mediaUrls,
    Map<String, dynamic>? pollData,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    bool? isReported,
    Map<String, dynamic>? metadata,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      authorTitle: authorTitle ?? this.authorTitle,
      content: content ?? this.content,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      pollData: pollData ?? this.pollData,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isReported: isReported ?? this.isReported,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isLikedByCurrentUser {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && likedBy.contains(currentUser.uid);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
