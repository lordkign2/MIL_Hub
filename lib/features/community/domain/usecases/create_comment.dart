import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../repositories/comment_repository.dart';

/// Use case for creating a comment
class CreateCommentUseCase {
  final CommentRepository _repository;

  CreateCommentUseCase(this._repository);

  Future<({CommentEntity? comment, Failure? failure})> call(
    CommentEntity comment,
  ) async {
    // Validate required fields
    if (comment.content.trim().isEmpty) {
      return (
        comment: null,
        failure: const ValidationFailure(
          message: 'Comment content cannot be empty',
        ),
      );
    }

    if (comment.postId.isEmpty) {
      return (
        comment: null,
        failure: const ValidationFailure(message: 'Post ID is required'),
      );
    }

    if (comment.authorId.isEmpty) {
      return (
        comment: null,
        failure: const ValidationFailure(message: 'Author ID is required'),
      );
    }

    if (comment.authorName.isEmpty) {
      return (
        comment: null,
        failure: const ValidationFailure(message: 'Author name is required'),
      );
    }

    return await _repository.createComment(comment);
  }
}
