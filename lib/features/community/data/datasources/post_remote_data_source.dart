import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../../../../core/errors/exceptions.dart';

/// Abstract interface for remote post data source
abstract class PostRemoteDataSource {
  /// Get all posts from remote source
  Future<List<PostModel>> getAllPosts({int limit = 20, String? lastPostId});

  /// Get a post by ID from remote source
  Future<PostModel> getPostById(String id);

  /// Create a new post in remote source
  Future<PostModel> createPost(PostModel post);

  /// Update an existing post in remote source
  Future<PostModel> updatePost(PostModel post);

  /// Delete a post from remote source
  Future<void> deletePost(String id);

  /// Like a post in remote source
  Future<void> likePost({required String postId, required String userId});

  /// Unlike a post in remote source
  Future<void> unlikePost({required String postId, required String userId});

  /// Get posts by author from remote source
  Future<List<PostModel>> getPostsByAuthor({
    required String authorId,
    int limit = 20,
    String? lastPostId,
  });

  /// Get posts by tag from remote source
  Future<List<PostModel>> getPostsByTag({
    required String tag,
    int limit = 20,
    String? lastPostId,
  });

  /// Report a post in remote source
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reporterId,
  });

  /// Pin a post in remote source
  Future<void> pinPost(String postId);

  /// Archive a post in remote source
  Future<void> archivePost(String postId);
}

/// Firebase implementation of PostRemoteDataSource
class FirebasePostRemoteDataSource implements PostRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebasePostRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<PostModel>> getAllPosts({
    int limit = 20,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastPostDoc = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        if (lastPostDoc.exists) {
          query = query.startAfterDocument(lastPostDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get posts: $e');
    }
  }

  @override
  Future<PostModel> getPostById(String id) async {
    try {
      final doc = await _firestore.collection('posts').doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Post not found');
      }
      return PostModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get post: $e');
    }
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    try {
      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());
      final createdPost = post.copyWith(id: docRef.id);
      await docRef.update(createdPost.toFirestore());
      return createdPost;
    } catch (e) {
      throw ServerException(message: 'Failed to create post: $e');
    }
  }

  @override
  Future<PostModel> updatePost(PostModel post) async {
    try {
      await _firestore
          .collection('posts')
          .doc(post.id)
          .update(post.toFirestore());
      return post;
    } catch (e) {
      throw ServerException(message: 'Failed to update post: $e');
    }
  }

  @override
  Future<void> deletePost(String id) async {
    try {
      await _firestore.collection('posts').doc(id).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete post: $e');
    }
  }

  @override
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw const ServerException(message: 'Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);

        if (!likedBy.contains(userId)) {
          likedBy.add(userId);
          postData['likedBy'] = likedBy;
          postData['likeCount'] = (postData['likeCount'] ?? 0) + 1;
          transaction.update(postRef, postData);
        }
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to like post: $e');
    }
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw const ServerException(message: 'Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          postData['likedBy'] = likedBy;
          postData['likeCount'] = (postData['likeCount'] ?? 1) - 1;
          transaction.update(postRef, postData);
        }
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to unlike post: $e');
    }
  }

  @override
  Future<List<PostModel>> getPostsByAuthor({
    required String authorId,
    int limit = 20,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastPostDoc = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        if (lastPostDoc.exists) {
          query = query.startAfterDocument(lastPostDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get posts by author: $e');
    }
  }

  @override
  Future<List<PostModel>> getPostsByTag({
    required String tag,
    int limit = 20,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastPostDoc = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        if (lastPostDoc.exists) {
          query = query.startAfterDocument(lastPostDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get posts by tag: $e');
    }
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reason': reason,
        'reporterId': reporterId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw ServerException(message: 'Failed to report post: $e');
    }
  }

  @override
  Future<void> pinPost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'isPinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to pin post: $e');
    }
  }

  @override
  Future<void> archivePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to archive post: $e');
    }
  }
}
