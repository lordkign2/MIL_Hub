import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';

/// Abstract repository interface for post operations
abstract class PostRepository {
  /// Get all posts
  Future<({List<PostEntity>? posts, Failure? failure})> getAllPosts({
    int limit = 20,
    String? lastPostId,
  });

  /// Get a post by ID
  Future<({PostEntity? post, Failure? failure})> getPostById(String id);

  /// Create a new post
  Future<({PostEntity? post, Failure? failure})> createPost(PostEntity post);

  /// Update an existing post
  Future<({PostEntity? post, Failure? failure})> updatePost(PostEntity post);

  /// Delete a post
  Future<({bool success, Failure? failure})> deletePost(String id);

  /// Like a post
  Future<({bool success, Failure? failure})> likePost({
    required String postId,
    required String userId,
  });

  /// Unlike a post
  Future<({bool success, Failure? failure})> unlikePost({
    required String postId,
    required String userId,
  });

  /// Get posts by author
  Future<({List<PostEntity>? posts, Failure? failure})> getPostsByAuthor({
    required String authorId,
    int limit = 20,
    String? lastPostId,
  });

  /// Get posts by tag
  Future<({List<PostEntity>? posts, Failure? failure})> getPostsByTag({
    required String tag,
    int limit = 20,
    String? lastPostId,
  });

  /// Report a post
  Future<({bool success, Failure? failure})> reportPost({
    required String postId,
    required String reason,
    required String reporterId,
  });

  /// Pin a post
  Future<({bool success, Failure? failure})> pinPost(String postId);

  /// Archive a post
  Future<({bool success, Failure? failure})> archivePost(String postId);
}
