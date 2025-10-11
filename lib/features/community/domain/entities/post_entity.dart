/// Post entity representing a community post in the domain layer
class PostEntity {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String? authorTitle;
  final String content;
  final String type; // Using String instead of enum for serialization
  final String privacy; // Using String instead of enum for serialization
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

  const PostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    this.authorTitle,
    required this.content,
    required this.type,
    required this.privacy,
    this.mediaUrls,
    this.pollData,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.viewCount,
    required this.likedBy,
    required this.createdAt,
    this.updatedAt,
    required this.isPinned,
    required this.isArchived,
    required this.isReported,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PostEntity{id: $id, authorName: $authorName, content: $content}';
  }
}
