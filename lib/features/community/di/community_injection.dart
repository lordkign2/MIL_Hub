import '../../../core/di/service_locator.dart';
import '../../../core/network/network_info.dart';
import '../data/datasources/comment_remote_data_source.dart';
import '../data/datasources/post_remote_data_source.dart';
import '../data/repositories/comment_repository_impl.dart';
import '../data/repositories/post_repository_impl.dart';
import '../domain/repositories/comment_repository.dart';
import '../domain/repositories/post_repository.dart';
import '../domain/usecases/create_comment.dart';
import '../domain/usecases/create_post.dart';
import '../domain/usecases/get_all_posts.dart';
import '../domain/usecases/like_post.dart';
import '../presentation/bloc/community_bloc.dart';

/// Initialize community feature dependencies
Future<void> initCommunityDependencies() async {
  // Data sources
  sl.registerSingleton<PostRemoteDataSource>(FirebasePostRemoteDataSource());
  sl.registerSingleton<CommentRemoteDataSource>(
    FirebaseCommentRemoteDataSource(),
  );

  // Repositories
  sl.registerSingleton<PostRepository>(
    PostRepositoryImpl(
      remoteDataSource: sl.get<PostRemoteDataSource>(),
      networkInfo: sl.get<NetworkInfo>(),
    ),
  );

  sl.registerSingleton<CommentRepository>(
    CommentRepositoryImpl(
      remoteDataSource: sl.get<CommentRemoteDataSource>(),
      networkInfo: sl.get<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerSingleton<GetAllPostsUseCase>(
    GetAllPostsUseCase(sl.get<PostRepository>()),
  );

  sl.registerSingleton<CreatePostUseCase>(
    CreatePostUseCase(sl.get<PostRepository>()),
  );

  sl.registerSingleton<LikePostUseCase>(
    LikePostUseCase(sl.get<PostRepository>()),
  );

  sl.registerSingleton<CreateCommentUseCase>(
    CreateCommentUseCase(sl.get<CommentRepository>()),
  );

  // BLoC
  sl.registerFactory<CommunityBloc>(
    () => CommunityBloc(
      getAllPosts: sl.get<GetAllPostsUseCase>(),
      createPost: sl.get<CreatePostUseCase>(),
      likePost: sl.get<LikePostUseCase>(),
      createComment: sl.get<CreateCommentUseCase>(),
    ),
  );
}
