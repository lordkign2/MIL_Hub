import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

/// Use case for getting all posts
class GetAllPostsUseCase {
  final PostRepository _repository;

  GetAllPostsUseCase(this._repository);

  Future<({List<PostEntity>? posts, Failure? failure})> call({
    int limit = 20,
    String? lastPostId,
  }) async {
    if (limit <= 0) {
      return (
        posts: null,
        failure: const ValidationFailure(
          message: 'Limit must be greater than 0',
        ),
      );
    }

    return await _repository.getAllPosts(limit: limit, lastPostId: lastPostId);
  }
}
