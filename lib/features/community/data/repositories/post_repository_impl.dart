import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_data_source.dart';
import '../models/post_model.dart';

/// Implementation of PostRepository
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  PostRepositoryImpl({
    required PostRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<({List<PostEntity>? posts, Failure? failure})> getAllPosts({
    int limit = 20,
    String? lastPostId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModels = await _remoteDataSource.getAllPosts(
          limit: limit,
          lastPostId: lastPostId,
        );
        final posts = postModels.map((model) => model.toEntity()).toList();
        return (posts: posts, failure: null);
      } on ServerException catch (e) {
        return (posts: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (posts: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          posts: null,
          failure: UnknownFailure(message: 'Failed to get posts: $e'),
        );
      }
    } else {
      return (
        posts: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({PostEntity? post, Failure? failure})> getPostById(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModel = await _remoteDataSource.getPostById(id);
        return (post: postModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (post: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (post: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          post: null,
          failure: UnknownFailure(message: 'Failed to get post: $e'),
        );
      }
    } else {
      return (
        post: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({PostEntity? post, Failure? failure})> createPost(
    PostEntity post,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModel = PostModel.fromEntity(post);
        final createdModel = await _remoteDataSource.createPost(postModel);
        return (post: createdModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (post: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (post: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          post: null,
          failure: UnknownFailure(message: 'Failed to create post: $e'),
        );
      }
    } else {
      return (
        post: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({PostEntity? post, Failure? failure})> updatePost(
    PostEntity post,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModel = PostModel.fromEntity(post);
        final updatedModel = await _remoteDataSource.updatePost(postModel);
        return (post: updatedModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (post: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (post: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          post: null,
          failure: UnknownFailure(message: 'Failed to update post: $e'),
        );
      }
    } else {
      return (
        post: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> deletePost(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.deletePost(id);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to delete post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> likePost({
    required String postId,
    required String userId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.likePost(postId: postId, userId: userId);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to like post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> unlikePost({
    required String postId,
    required String userId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.unlikePost(postId: postId, userId: userId);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to unlike post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({List<PostEntity>? posts, Failure? failure})> getPostsByAuthor({
    required String authorId,
    int limit = 20,
    String? lastPostId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModels = await _remoteDataSource.getPostsByAuthor(
          authorId: authorId,
          limit: limit,
          lastPostId: lastPostId,
        );
        final posts = postModels.map((model) => model.toEntity()).toList();
        return (posts: posts, failure: null);
      } on ServerException catch (e) {
        return (posts: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (posts: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          posts: null,
          failure: UnknownFailure(message: 'Failed to get posts by author: $e'),
        );
      }
    } else {
      return (
        posts: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({List<PostEntity>? posts, Failure? failure})> getPostsByTag({
    required String tag,
    int limit = 20,
    String? lastPostId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final postModels = await _remoteDataSource.getPostsByTag(
          tag: tag,
          limit: limit,
          lastPostId: lastPostId,
        );
        final posts = postModels.map((model) => model.toEntity()).toList();
        return (posts: posts, failure: null);
      } on ServerException catch (e) {
        return (posts: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (posts: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          posts: null,
          failure: UnknownFailure(message: 'Failed to get posts by tag: $e'),
        );
      }
    } else {
      return (
        posts: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> reportPost({
    required String postId,
    required String reason,
    required String reporterId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.reportPost(
          postId: postId,
          reason: reason,
          reporterId: reporterId,
        );
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to report post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> pinPost(String postId) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.pinPost(postId);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to pin post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> archivePost(String postId) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.archivePost(postId);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to archive post: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }
}
