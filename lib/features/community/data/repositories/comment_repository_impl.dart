import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';
import '../models/comment_model.dart';

/// Implementation of CommentRepository
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  CommentRepositoryImpl({
    required CommentRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<({List<CommentEntity>? comments, Failure? failure})>
  getCommentsForPost({
    required String postId,
    int limit = 20,
    String? lastCommentId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final commentModels = await _remoteDataSource.getCommentsForPost(
          postId: postId,
          limit: limit,
          lastCommentId: lastCommentId,
        );
        final comments = commentModels
            .map((model) => model.toEntity())
            .toList();
        return (comments: comments, failure: null);
      } on ServerException catch (e) {
        return (comments: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (comments: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          comments: null,
          failure: UnknownFailure(message: 'Failed to get comments: $e'),
        );
      }
    } else {
      return (
        comments: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({CommentEntity? comment, Failure? failure})> getCommentById(
    String id,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final commentModel = await _remoteDataSource.getCommentById(id);
        return (comment: commentModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (comment: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (comment: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          comment: null,
          failure: UnknownFailure(message: 'Failed to get comment: $e'),
        );
      }
    } else {
      return (
        comment: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({CommentEntity? comment, Failure? failure})> createComment(
    CommentEntity comment,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final commentModel = CommentModel.fromEntity(comment);
        final createdModel = await _remoteDataSource.createComment(
          commentModel,
        );
        return (comment: createdModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (comment: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (comment: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          comment: null,
          failure: UnknownFailure(message: 'Failed to create comment: $e'),
        );
      }
    } else {
      return (
        comment: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({CommentEntity? comment, Failure? failure})> updateComment(
    CommentEntity comment,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final commentModel = CommentModel.fromEntity(comment);
        final updatedModel = await _remoteDataSource.updateComment(
          commentModel,
        );
        return (comment: updatedModel.toEntity(), failure: null);
      } on ServerException catch (e) {
        return (comment: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (comment: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          comment: null,
          failure: UnknownFailure(message: 'Failed to update comment: $e'),
        );
      }
    } else {
      return (
        comment: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> deleteComment(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.deleteComment(id);
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to delete comment: $e'),
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
  Future<({bool success, Failure? failure})> likeComment({
    required String commentId,
    required String userId,
    required String reactionType,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.likeComment(
          commentId: commentId,
          userId: userId,
          reactionType: reactionType,
        );
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to like comment: $e'),
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
  Future<({bool success, Failure? failure})> unlikeComment({
    required String commentId,
    required String userId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.unlikeComment(
          commentId: commentId,
          userId: userId,
        );
        return (success: true, failure: null);
      } on ServerException catch (e) {
        return (success: false, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to unlike comment: $e'),
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
  Future<({List<CommentEntity>? comments, Failure? failure})>
  getRepliesForComment({
    required String commentId,
    int limit = 20,
    String? lastCommentId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final commentModels = await _remoteDataSource.getRepliesForComment(
          commentId: commentId,
          limit: limit,
          lastCommentId: lastCommentId,
        );
        final comments = commentModels
            .map((model) => model.toEntity())
            .toList();
        return (comments: comments, failure: null);
      } on ServerException catch (e) {
        return (comments: null, failure: ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return (comments: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          comments: null,
          failure: UnknownFailure(message: 'Failed to get replies: $e'),
        );
      }
    } else {
      return (
        comments: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> reportComment({
    required String commentId,
    required String reason,
    required String reporterId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.reportComment(
          commentId: commentId,
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
          failure: UnknownFailure(message: 'Failed to report comment: $e'),
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
