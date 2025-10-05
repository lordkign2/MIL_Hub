import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get display name from Firestore
  static Future<String?> _getDisplayNameFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['displayName'] as String?;
      }
    } catch (e) {
      // Log error but don't throw to allow fallback to 'Anonymous User'
      print('Error getting display name from Firestore: $e');
    }
    return null;
  }

  // Collections
  static const String _postsCollection = 'communityPosts';
  static const String _commentsCollection = 'comments';
  static const String _likesCollection = 'likes';
  static const String _userStatsCollection = 'userCommunityStats';

  // Posts
  static Stream<List<PostModel>> getPostsStream({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? tags,
  }) {
    Query query = _firestore
        .collection(_postsCollection)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('content', isGreaterThanOrEqualTo: searchQuery)
          .where('content', isLessThan: searchQuery + 'z');
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Sort pinned posts to the top after getting data
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return posts;
    });
  }

  static Future<String> createPost({
    required String content,
    PostType type = PostType.text,
    List<String>? mediaUrls,
    Map<String, dynamic>? pollData,
    List<String> tags = const [],
    PostPrivacy privacy = PostPrivacy.public,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final post = PostModel(
      id: '',
      authorId: user.uid,
      authorName:
          user.displayName ??
          (await _getDisplayNameFromFirestore(user.uid)) ??
          'Anonymous User',
      authorPhoto: user.photoURL,
      content: content,
      type: type,
      privacy: privacy,
      mediaUrls: mediaUrls,
      pollData: pollData,
      tags: tags,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_postsCollection)
        .add(post.toFirestore());

    // Update user stats
    await _updateUserStats(user.uid, 'postsCount', 1);

    return docRef.id;
  }

  static Future<void> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection(_postsCollection).doc(postId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost(String postId) async {
    final batch = _firestore.batch();

    // Mark post as archived instead of deleting
    batch.update(_firestore.collection(_postsCollection).doc(postId), {
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Likes
  static Future<void> toggleLike(
    String postId, {
    bool isComment = false,
    String? commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final collection = isComment ? _commentsCollection : _postsCollection;
    final docId = isComment ? commentId! : postId;
    final docRef = _firestore.collection(collection).doc(docId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likeCount = data['likeCount'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likeCount': likeCount - 1,
        });
      } else {
        // Like
        likedBy.add(user.uid);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likeCount': likeCount + 1,
        });

        // Add to likes subcollection for detailed tracking
        if (!isComment) {
          transaction.set(
            _firestore
                .collection(_postsCollection)
                .doc(postId)
                .collection(_likesCollection)
                .doc(user.uid),
            {
              'userId': user.uid,
              'userName': user.displayName ?? 'Anonymous',
              'userPhoto': user.photoURL,
              'likedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
    });

    // Update user stats
    if (!isComment) {
      await _updateUserStats(user.uid, 'likesGiven', 1);
    }
  }

  static Stream<List<Map<String, dynamic>>> getPostLikes(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_likesCollection)
        .orderBy('likedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Comments
  static Stream<List<CommentModel>> getCommentsStream(
    String postId, {
    String? parentCommentId,
  }) {
    Query query = _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .where('isReported', isEqualTo: false)
        .orderBy('createdAt', descending: false);

    if (parentCommentId != null) {
      query = query.where('parentCommentId', isEqualTo: parentCommentId);
    } else {
      query = query.where('parentCommentId', isNull: true);
    }

    return query.snapshots().map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();

      // Sort pinned comments to the top after getting data
      comments.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      return comments;
    });
  }

  static Future<String> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    CommentType type = CommentType.text,
    String? mediaUrl,
    List<String> mentionedUsers = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final comment = CommentModel(
      id: '',
      postId: postId,
      authorId: user.uid,
      authorName: user.displayName ?? 'Anonymous User',
      authorPhoto: user.photoURL,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      parentCommentId: parentCommentId,
      mentionedUsers: mentionedUsers,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .add(comment.toFirestore());

    // Update comment count on post
    await _firestore.collection(_postsCollection).doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    // Update reply count on parent comment if this is a reply
    if (parentCommentId != null) {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .doc(parentCommentId)
          .update({'replyCount': FieldValue.increment(1)});
    }

    // Update user stats
    await _updateUserStats(user.uid, 'commentsCount', 1);

    return docRef.id;
  }

  static Future<void> updateComment(
    String postId,
    String commentId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .doc(commentId)
        .update({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
          'isEdited': true,
        });
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    // Mark as reported instead of deleting to maintain thread integrity
    await _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .doc(commentId)
        .update({
          'isReported': true,
          'content': '[Comment deleted]',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Reactions for comments
  static Future<void> addCommentReaction(
    String postId,
    String commentId,
    ReactionType reaction,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final commentRef = _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final reactions = Map<String, int>.from(data['reactions'] ?? {});
      final userReactions = Map<String, String>.from(
        data['userReactions'] ?? {},
      );

      final reactionKey = reaction.toString().split('.').last;
      final previousReaction = userReactions[user.uid];

      // Remove previous reaction if exists
      if (previousReaction != null) {
        reactions[previousReaction] = (reactions[previousReaction] ?? 1) - 1;
        if (reactions[previousReaction]! <= 0) {
          reactions.remove(previousReaction);
        }
      }

      // Add new reaction
      reactions[reactionKey] = (reactions[reactionKey] ?? 0) + 1;
      userReactions[user.uid] = reactionKey;

      transaction.update(commentRef, {
        'reactions': reactions,
        'userReactions': userReactions,
      });
    });
  }

  // User Stats
  static Future<void> _updateUserStats(
    String userId,
    String field,
    int increment,
  ) async {
    await _firestore.collection(_userStatsCollection).doc(userId).set({
      field: FieldValue.increment(increment),
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<Map<String, dynamic>?> getUserStats(String userId) {
    return _firestore
        .collection(_userStatsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Search and filtering
  static Future<List<PostModel>> searchPosts(
    String query, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection(_postsCollection)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + 'z')
        .where('isArchived', isEqualTo: false)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  static Future<List<String>> getTrendingTags({int limit = 10}) async {
    // This would typically be implemented with cloud functions
    // For now, return some sample trending tags
    return [
      '#MediaLiteracy',
      '#FactCheck',
      '#DigitalSafety',
      '#CriticalThinking',
      '#NewsVerification',
    ];
  }

  // Report content
  static Future<void> reportContent({
    required String contentId,
    required String contentType, // 'post' or 'comment'
    required String reason,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('reports').add({
      'contentId': contentId,
      'contentType': contentType,
      'reportedBy': user.uid,
      'reason': reason,
      'description': description,
      'reportedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
