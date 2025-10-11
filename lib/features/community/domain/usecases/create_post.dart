import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

/// Use case for creating a post
class CreatePostUseCase {
  final PostRepository _repository;

  CreatePostUseCase(this._repository);

  Future<({PostEntity? post, Failure? failure})> call(PostEntity post) async {
    // Validate required fields
    if (post.content.trim().isEmpty) {
      return (
        post: null,
        failure: const ValidationFailure(
          message: 'Post content cannot be empty',
        ),
      );
    }

    if (post.authorId.isEmpty) {
      return (
        post: null,
        failure: const ValidationFailure(message: 'Author ID is required'),
      );
    }

    if (post.authorName.isEmpty) {
      return (
        post: null,
        failure: const ValidationFailure(message: 'Author name is required'),
      );
    }

    return await _repository.createPost(post);
  }
}
