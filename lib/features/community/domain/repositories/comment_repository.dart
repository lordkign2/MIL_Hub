import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';

/// Abstract repository interface for comment operations
abstract class CommentRepository {
  /// Get comments for a post
  Future<({List<CommentEntity>? comments, Failure? failure})>
  getCommentsForPost({
    required String postId,
    int limit = 20,
    String? lastCommentId,
  });

  /// Get a comment by ID
  Future<({CommentEntity? comment, Failure? failure})> getCommentById(
    String id,
  );

  /// Create a new comment
  Future<({CommentEntity? comment, Failure? failure})> createComment(
    CommentEntity comment,
  );

  /// Update an existing comment
  Future<({CommentEntity? comment, Failure? failure})> updateComment(
    CommentEntity comment,
  );

  /// Delete a comment
  Future<({bool success, Failure? failure})> deleteComment(String id);

  /// Like a comment
  Future<({bool success, Failure? failure})> likeComment({
    required String commentId,
    required String userId,
    required String reactionType,
  });

  /// Unlike a comment
  Future<({bool success, Failure? failure})> unlikeComment({
    required String commentId,
    required String userId,
  });

  /// Get replies for a comment
  Future<({List<CommentEntity>? comments, Failure? failure})>
  getRepliesForComment({
    required String commentId,
    int limit = 20,
    String? lastCommentId,
  });

  /// Report a comment
  Future<({bool success, Failure? failure})> reportComment({
    required String commentId,
    required String reason,
    required String reporterId,
  });
}
