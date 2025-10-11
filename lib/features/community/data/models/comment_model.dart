import '../../domain/entities/comment_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model for data layer that extends the domain entity
class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    required super.authorName,
    super.authorPhoto,
    super.authorTitle,
    required super.content,
    required super.type,
    super.mediaUrl,
    super.parentCommentId,
    required super.mentionedUsers,
    required super.reactions,
    required super.userReactions,
    required super.replyCount,
    required super.createdAt,
    super.updatedAt,
    required super.isEdited,
    required super.isReported,
    required super.isPinned,
  });

  /// Create CommentModel from Comment entity
  factory CommentModel.fromEntity(CommentEntity entity) {
    return CommentModel(
      id: entity.id,
      postId: entity.postId,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorPhoto: entity.authorPhoto,
      authorTitle: entity.authorTitle,
      content: entity.content,
      type: entity.type,
      mediaUrl: entity.mediaUrl,
      parentCommentId: entity.parentCommentId,
      mentionedUsers: entity.mentionedUsers,
      reactions: entity.reactions,
      userReactions: entity.userReactions,
      replyCount: entity.replyCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isEdited: entity.isEdited,
      isReported: entity.isReported,
      isPinned: entity.isPinned,
    );
  }

  /// Create CommentModel from Firestore Document
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse reactions map
    Map<String, int> reactions = {};
    if (data['reactions'] != null) {
      (data['reactions'] as Map<String, dynamic>).forEach((key, value) {
        reactions[key] = value as int;
      });
    }

    // Parse user reactions map
    Map<String, String> userReactions = {};
    if (data['userReactions'] != null) {
      (data['userReactions'] as Map<String, dynamic>).forEach((key, value) {
        userReactions[key] = value as String;
      });
    }

    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhoto: data['authorPhoto'],
      authorTitle: data['authorTitle'],
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      parentCommentId: data['parentCommentId'],
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'])
          : [],
      reactions: reactions,
      userReactions: userReactions,
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isEdited: data['isEdited'] ?? false,
      isReported: data['isReported'] ?? false,
      isPinned: data['isPinned'] ?? false,
    );
  }

  /// Convert CommentModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'authorTitle': authorTitle,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'parentCommentId': parentCommentId,
      'mentionedUsers': mentionedUsers,
      'reactions': reactions,
      'userReactions': userReactions,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
      'isReported': isReported,
      'isPinned': isPinned,
    };
  }

  /// Convert to CommentEntity
  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      authorTitle: authorTitle,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      parentCommentId: parentCommentId,
      mentionedUsers: mentionedUsers,
      reactions: reactions,
      userReactions: userReactions,
      replyCount: replyCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isEdited: isEdited,
      isReported: isReported,
      isPinned: isPinned,
    );
  }

  /// Create a copy of the CommentModel with specified fields updated
  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    String? authorTitle,
    String? content,
    String? type,
    String? mediaUrl,
    String? parentCommentId,
    List<String>? mentionedUsers,
    Map<String, int>? reactions,
    Map<String, String>? userReactions,
    int? replyCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isReported,
    bool? isPinned,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      authorTitle: authorTitle ?? this.authorTitle,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isReported: isReported ?? this.isReported,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
