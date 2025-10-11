import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../../../../core/errors/exceptions.dart';

/// Abstract interface for remote comment data source
abstract class CommentRemoteDataSource {
  /// Get comments for a post from remote source
  Future<List<CommentModel>> getCommentsForPost({
    required String postId,
    int limit = 20,
    String? lastCommentId,
  });

  /// Get a comment by ID from remote source
  Future<CommentModel> getCommentById(String id);

  /// Create a new comment in remote source
  Future<CommentModel> createComment(CommentModel comment);

  /// Update an existing comment in remote source
  Future<CommentModel> updateComment(CommentModel comment);

  /// Delete a comment from remote source
  Future<void> deleteComment(String id);

  /// Like a comment in remote source
  Future<void> likeComment({
    required String commentId,
    required String userId,
    required String reactionType,
  });

  /// Unlike a comment in remote source
  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  });

  /// Get replies for a comment from remote source
  Future<List<CommentModel>> getRepliesForComment({
    required String commentId,
    int limit = 20,
    String? lastCommentId,
  });

  /// Report a comment in remote source
  Future<void> reportComment({
    required String commentId,
    required String reason,
    required String reporterId,
  });
}

/// Firebase implementation of CommentRemoteDataSource
class FirebaseCommentRemoteDataSource implements CommentRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseCommentRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CommentModel>> getCommentsForPost({
    required String postId,
    int limit = 20,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentCommentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastCommentId != null) {
        final lastCommentDoc = await _firestore
            .collection('comments')
            .doc(lastCommentId)
            .get();
        if (lastCommentDoc.exists) {
          query = query.startAfterDocument(lastCommentDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get comments: $e');
    }
  }

  @override
  Future<CommentModel> getCommentById(String id) async {
    try {
      final doc = await _firestore.collection('comments').doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Comment not found');
      }
      return CommentModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get comment: $e');
    }
  }

  @override
  Future<CommentModel> createComment(CommentModel comment) async {
    try {
      final docRef = await _firestore
          .collection('comments')
          .add(comment.toFirestore());
      final createdComment = comment.copyWith(id: docRef.id);
      await docRef.update(createdComment.toFirestore());
      return createdComment;
    } catch (e) {
      throw ServerException(message: 'Failed to create comment: $e');
    }
  }

  @override
  Future<CommentModel> updateComment(CommentModel comment) async {
    try {
      await _firestore
          .collection('comments')
          .doc(comment.id)
          .update(comment.toFirestore());
      return comment;
    } catch (e) {
      throw ServerException(message: 'Failed to update comment: $e');
    }
  }

  @override
  Future<void> deleteComment(String id) async {
    try {
      await _firestore.collection('comments').doc(id).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete comment: $e');
    }
  }

  @override
  Future<void> likeComment({
    required String commentId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) {
          throw const ServerException(message: 'Comment not found');
        }

        final commentData = commentDoc.data() as Map<String, dynamic>;
        final userReactions = Map<String, String>.from(
          commentData['userReactions'] ?? {},
        );
        final reactions = Map<String, int>.from(commentData['reactions'] ?? {});

        // Remove previous reaction if exists
        if (userReactions.containsKey(userId)) {
          final previousReaction = userReactions[userId]!;
          reactions[previousReaction] = (reactions[previousReaction] ?? 1) - 1;
        }

        // Add new reaction
        userReactions[userId] = reactionType;
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;

        commentData['userReactions'] = userReactions;
        commentData['reactions'] = reactions;
        transaction.update(commentRef, commentData);
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to like comment: $e');
    }
  }

  @override
  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) {
          throw const ServerException(message: 'Comment not found');
        }

        final commentData = commentDoc.data() as Map<String, dynamic>;
        final userReactions = Map<String, String>.from(
          commentData['userReactions'] ?? {},
        );
        final reactions = Map<String, int>.from(commentData['reactions'] ?? {});

        // Remove reaction if exists
        if (userReactions.containsKey(userId)) {
          final reactionType = userReactions[userId]!;
          userReactions.remove(userId);
          reactions[reactionType] = (reactions[reactionType] ?? 1) - 1;

          commentData['userReactions'] = userReactions;
          commentData['reactions'] = reactions;
          transaction.update(commentRef, commentData);
        }
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to unlike comment: $e');
    }
  }

  @override
  Future<List<CommentModel>> getRepliesForComment({
    required String commentId,
    int limit = 20,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastCommentId != null) {
        final lastCommentDoc = await _firestore
            .collection('comments')
            .doc(lastCommentId)
            .get();
        if (lastCommentDoc.exists) {
          query = query.startAfterDocument(lastCommentDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get replies: $e');
    }
  }

  @override
  Future<void> reportComment({
    required String commentId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'commentId': commentId,
        'reason': reason,
        'reporterId': reporterId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw ServerException(message: 'Failed to report comment: $e');
    }
  }
}
