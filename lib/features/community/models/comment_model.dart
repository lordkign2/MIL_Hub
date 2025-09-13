import 'package:cloud_firestore/cloud_firestore.dart';

enum CommentType { text, image, gif, sticker }

enum ReactionType { like, love, laugh, angry, sad, wow }

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String? authorTitle;
  final String content;
  final CommentType type;
  final String? mediaUrl;
  final String? parentCommentId; // For threaded replies
  final List<String> mentionedUsers;
  final Map<ReactionType, int> reactions;
  final Map<String, ReactionType> userReactions; // userId -> reaction
  final int replyCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isReported;
  final bool isPinned;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    this.authorTitle,
    required this.content,
    this.type = CommentType.text,
    this.mediaUrl,
    this.parentCommentId,
    this.mentionedUsers = const [],
    this.reactions = const {},
    this.userReactions = const {},
    this.replyCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isReported = false,
    this.isPinned = false,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse reactions map
    Map<ReactionType, int> reactions = {};
    if (data['reactions'] != null) {
      (data['reactions'] as Map<String, dynamic>).forEach((key, value) {
        final reactionType = ReactionType.values.firstWhere(
          (type) => type.toString() == 'ReactionType.$key',
          orElse: () => ReactionType.like,
        );
        reactions[reactionType] = value as int;
      });
    }

    // Parse user reactions map
    Map<String, ReactionType> userReactions = {};
    if (data['userReactions'] != null) {
      (data['userReactions'] as Map<String, dynamic>).forEach((key, value) {
        final reactionType = ReactionType.values.firstWhere(
          (type) => type.toString() == 'ReactionType.$value',
          orElse: () => ReactionType.like,
        );
        userReactions[key] = reactionType;
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
      type: CommentType.values.firstWhere(
        (type) => type.toString() == 'CommentType.${data['type']}',
        orElse: () => CommentType.text,
      ),
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

  Map<String, dynamic> toFirestore() {
    // Convert reactions to Firestore format
    Map<String, int> reactionsMap = {};
    reactions.forEach((key, value) {
      reactionsMap[key.toString().split('.').last] = value;
    });

    // Convert user reactions to Firestore format
    Map<String, String> userReactionsMap = {};
    userReactions.forEach((key, value) {
      userReactionsMap[key] = value.toString().split('.').last;
    });

    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'authorTitle': authorTitle,
      'content': content,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'parentCommentId': parentCommentId,
      'mentionedUsers': mentionedUsers,
      'reactions': reactionsMap,
      'userReactions': userReactionsMap,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
      'isReported': isReported,
      'isPinned': isPinned,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    String? authorTitle,
    String? content,
    CommentType? type,
    String? mediaUrl,
    String? parentCommentId,
    List<String>? mentionedUsers,
    Map<ReactionType, int>? reactions,
    Map<String, ReactionType>? userReactions,
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

  bool get isReply => parentCommentId != null;

  int get totalReactions =>
      reactions.values.fold(0, (sum, count) => sum + count);

  ReactionType? getUserReaction(String userId) => userReactions[userId];

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
