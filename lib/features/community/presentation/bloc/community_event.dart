import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

/// Base class for all community events
abstract class CommunityEvent {
  const CommunityEvent();
}

/// Event to load all posts
class LoadPostsEvent extends CommunityEvent {
  final int limit;
  final String? lastPostId;

  const LoadPostsEvent({this.limit = 20, this.lastPostId});
}

/// Event to load a specific post by ID
class LoadPostByIdEvent extends CommunityEvent {
  final String id;

  const LoadPostByIdEvent({required this.id});
}

/// Event to create a new post
class CreatePostEvent extends CommunityEvent {
  final PostEntity post;

  const CreatePostEvent({required this.post});
}

/// Event to like a post
class LikePostEvent extends CommunityEvent {
  final String postId;
  final String userId;

  const LikePostEvent({required this.postId, required this.userId});
}

/// Event to unlike a post
class UnlikePostEvent extends CommunityEvent {
  final String postId;
  final String userId;

  const UnlikePostEvent({required this.postId, required this.userId});
}

/// Event to load comments for a post
class LoadCommentsEvent extends CommunityEvent {
  final String postId;
  final int limit;
  final String? lastCommentId;

  const LoadCommentsEvent({
    required this.postId,
    this.limit = 20,
    this.lastCommentId,
  });
}

/// Event to create a new comment
class CreateCommentEvent extends CommunityEvent {
  final CommentEntity comment;

  const CreateCommentEvent({required this.comment});
}

/// Event to like a comment
class LikeCommentEvent extends CommunityEvent {
  final String commentId;
  final String userId;
  final String reactionType;

  const LikeCommentEvent({
    required this.commentId,
    required this.userId,
    required this.reactionType,
  });
}

/// Event to unlike a comment
class UnlikeCommentEvent extends CommunityEvent {
  final String commentId;
  final String userId;

  const UnlikeCommentEvent({required this.commentId, required this.userId});
}

/// Event to refresh posts
class RefreshPostsEvent extends CommunityEvent {
  const RefreshPostsEvent();
}

/// Event to report a post
class ReportPostEvent extends CommunityEvent {
  final String postId;
  final String reason;
  final String reporterId;

  const ReportPostEvent({
    required this.postId,
    required this.reason,
    required this.reporterId,
  });
}
