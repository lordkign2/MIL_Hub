import '../../domain/entities/post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Post model for data layer that extends the domain entity
class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorPhoto,
    super.authorTitle,
    required super.content,
    required super.type,
    required super.privacy,
    super.mediaUrls,
    super.pollData,
    required super.tags,
    required super.likeCount,
    required super.commentCount,
    required super.shareCount,
    required super.viewCount,
    required super.likedBy,
    required super.createdAt,
    super.updatedAt,
    required super.isPinned,
    required super.isArchived,
    required super.isReported,
    super.metadata,
  });

  /// Create PostModel from Post entity
  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorPhoto: entity.authorPhoto,
      authorTitle: entity.authorTitle,
      content: entity.content,
      type: entity.type,
      privacy: entity.privacy,
      mediaUrls: entity.mediaUrls,
      pollData: entity.pollData,
      tags: entity.tags,
      likeCount: entity.likeCount,
      commentCount: entity.commentCount,
      shareCount: entity.shareCount,
      viewCount: entity.viewCount,
      likedBy: entity.likedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPinned: entity.isPinned,
      isArchived: entity.isArchived,
      isReported: entity.isReported,
      metadata: entity.metadata,
    );
  }

  /// Create PostModel from Firestore Document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhoto: data['authorPhoto'],
      authorTitle: data['authorTitle'],
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      privacy: data['privacy'] ?? 'public',
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

  /// Convert PostModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'authorTitle': authorTitle,
      'content': content,
      'type': type,
      'privacy': privacy,
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

  /// Convert to PostEntity
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      authorTitle: authorTitle,
      content: content,
      type: type,
      privacy: privacy,
      mediaUrls: mediaUrls,
      pollData: pollData,
      tags: tags,
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      viewCount: viewCount,
      likedBy: likedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
      isArchived: isArchived,
      isReported: isReported,
      metadata: metadata,
    );
  }

  /// Create a copy of the PostModel with specified fields updated
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    String? authorTitle,
    String? content,
    String? type,
    String? privacy,
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
}
