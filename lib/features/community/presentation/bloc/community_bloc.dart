import 'dart:async';
import '../../domain/usecases/create_comment.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/get_all_posts.dart';
import '../../domain/usecases/like_post.dart';

import 'community_event.dart';
import 'community_state.dart';

/// BLoC for handling community logic
class CommunityBloc {
  final GetAllPostsUseCase _getAllPosts;
  final CreatePostUseCase _createPost;
  final LikePostUseCase _likePost;
  final CreateCommentUseCase _createComment;

  // State management
  CommunityState _state = const CommunityInitial();
  final _stateController = StreamController<CommunityState>.broadcast();

  // Event handling
  final _eventController = StreamController<CommunityEvent>();
  late StreamSubscription _eventSubscription;

  CommunityBloc({
    required GetAllPostsUseCase getAllPosts,
    required CreatePostUseCase createPost,
    required LikePostUseCase likePost,
    required CreateCommentUseCase createComment,
  }) : _getAllPosts = getAllPosts,
       _createPost = createPost,
       _likePost = likePost,
       _createComment = createComment {
    // Initialize event handling
    _eventSubscription = _eventController.stream.listen(_handleEvent);
  }

  /// Current state
  CommunityState get state => _state;

  /// State stream
  Stream<CommunityState> get stream => _stateController.stream;

  /// Add event
  void add(CommunityEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Handle events
  Future<void> _handleEvent(CommunityEvent event) async {
    try {
      if (event is LoadPostsEvent) {
        await _handleLoadPosts(event);
      } else if (event is LoadPostByIdEvent) {
        await _handleLoadPostById(event);
      } else if (event is CreatePostEvent) {
        await _handleCreatePost(event);
      } else if (event is LikePostEvent) {
        await _handleLikePost(event);
      } else if (event is UnlikePostEvent) {
        await _handleUnlikePost(event);
      } else if (event is LoadCommentsEvent) {
        await _handleLoadComments(event);
      } else if (event is CreateCommentEvent) {
        await _handleCreateComment(event);
      } else if (event is LikeCommentEvent) {
        await _handleLikeComment(event);
      } else if (event is UnlikeCommentEvent) {
        await _handleUnlikeComment(event);
      } else if (event is RefreshPostsEvent) {
        await _handleRefreshPosts(event);
      } else if (event is ReportPostEvent) {
        await _handleReportPost(event);
      }
    } catch (e) {
      _emitState(CommunityError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _handleLoadPosts(LoadPostsEvent event) async {
    _emitState(const CommunityLoading());

    final result = await _getAllPosts(
      limit: event.limit,
      lastPostId: event.lastPostId,
    );

    if (result.posts != null) {
      _emitState(
        PostsLoaded(
          posts: result.posts!,
          comments: {}, // Initialize empty comments map
          hasMorePosts: result.posts!.length == event.limit,
        ),
      );
    } else {
      _emitState(
        CommunityError(
          message: result.failure?.message ?? 'Failed to load posts',
        ),
      );
    }
  }

  Future<void> _handleLoadPostById(LoadPostByIdEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleCreatePost(CreatePostEvent event) async {
    _emitState(const CommunityLoading());

    final result = await _createPost(event.post);

    if (result.post != null) {
      // Refresh posts after creating a new one
      add(const LoadPostsEvent());
      _emitState(
        const CommunityActionSuccess(message: 'Post created successfully'),
      );
    } else {
      _emitState(
        CommunityError(
          message: result.failure?.message ?? 'Failed to create post',
        ),
      );
    }
  }

  Future<void> _handleLikePost(LikePostEvent event) async {
    _emitState(const CommunityLoading());

    final result = await _likePost(postId: event.postId, userId: event.userId);

    if (result.success) {
      // Refresh posts to show updated like count
      add(const LoadPostsEvent());
      _emitState(const CommunityActionSuccess(message: 'Post liked'));
    } else {
      _emitState(
        CommunityError(
          message: result.failure?.message ?? 'Failed to like post',
        ),
      );
    }
  }

  Future<void> _handleUnlikePost(UnlikePostEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleLoadComments(LoadCommentsEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleCreateComment(CreateCommentEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleLikeComment(LikeCommentEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleUnlikeComment(UnlikeCommentEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  Future<void> _handleRefreshPosts(RefreshPostsEvent event) async {
    // Force refresh by clearing any cache and reloading
    add(const LoadPostsEvent());
  }

  Future<void> _handleReportPost(ReportPostEvent event) async {
    // Implementation would go here
    _emitState(const CommunityLoading());
  }

  void _emitState(CommunityState newState) {
    if (_state != newState && !_stateController.isClosed) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription.cancel();
    _eventController.close();
    _stateController.close();
  }
}
