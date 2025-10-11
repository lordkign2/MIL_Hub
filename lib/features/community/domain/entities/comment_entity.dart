/// Comment entity representing a community comment in the domain layer
class CommentEntity {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String? authorTitle;
  final String content;
  final String type; // Using String instead of enum for serialization
  final String? mediaUrl;
  final String? parentCommentId;
  final List<String> mentionedUsers;
  final Map<String, int> reactions; // reactionType -> count
  final Map<String, String> userReactions; // userId -> reactionType
  final int replyCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isReported;
  final bool isPinned;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    this.authorTitle,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.parentCommentId,
    required this.mentionedUsers,
    required this.reactions,
    required this.userReactions,
    required this.replyCount,
    required this.createdAt,
    this.updatedAt,
    required this.isEdited,
    required this.isReported,
    required this.isPinned,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommentEntity{id: $id, authorName: $authorName, content: $content}';
  }
}
