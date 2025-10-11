import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

/// Base class for all community states
abstract class CommunityState {
  const CommunityState();
}

/// Initial state
class CommunityInitial extends CommunityState {
  const CommunityInitial();
}

/// Loading state
class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

/// Loaded state with posts
class PostsLoaded extends CommunityState {
  final List<PostEntity> posts;
  final Map<String, List<CommentEntity>> comments; // postId -> comments
  final bool hasMorePosts;

  const PostsLoaded({
    required this.posts,
    required this.comments,
    required this.hasMorePosts,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostsLoaded &&
          runtimeType == other.runtimeType &&
          posts == other.posts &&
          comments == other.comments &&
          hasMorePosts == other.hasMorePosts;

  @override
  int get hashCode =>
      posts.hashCode ^ comments.hashCode ^ hasMorePosts.hashCode;
}

/// Loaded state with a single post
class PostLoaded extends CommunityState {
  final PostEntity post;
  final List<CommentEntity> comments;
  final bool hasMoreComments;

  const PostLoaded({
    required this.post,
    required this.comments,
    required this.hasMoreComments,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostLoaded &&
          runtimeType == other.runtimeType &&
          post == other.post &&
          comments == other.comments &&
          hasMoreComments == other.hasMoreComments;

  @override
  int get hashCode =>
      post.hashCode ^ comments.hashCode ^ hasMoreComments.hashCode;
}

/// Error state
class CommunityError extends CommunityState {
  final String message;

  const CommunityError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Success state for actions that don't return data
class CommunityActionSuccess extends CommunityState {
  final String message;

  const CommunityActionSuccess({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityActionSuccess &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
