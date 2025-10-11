import '../../../../core/errors/failures.dart';
import '../repositories/post_repository.dart';

/// Use case for liking a post
class LikePostUseCase {
  final PostRepository _repository;

  LikePostUseCase(this._repository);

  Future<({bool success, Failure? failure})> call({
    required String postId,
    required String userId,
  }) async {
    if (postId.isEmpty) {
      return (
        success: false,
        failure: const ValidationFailure(message: 'Post ID cannot be empty'),
      );
    }

    if (userId.isEmpty) {
      return (
        success: false,
        failure: const ValidationFailure(message: 'User ID cannot be empty'),
      );
    }

    return await _repository.likePost(postId: postId, userId: userId);
  }
}
