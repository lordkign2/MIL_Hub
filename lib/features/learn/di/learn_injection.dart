import '../../../core/di/service_locator.dart';
import '../../../core/network/network_info.dart';
import '../data/datasources/lesson_local_data_source.dart';
import '../data/datasources/lesson_remote_data_source.dart';
import '../data/repositories/lesson_repository_impl.dart';
import '../domain/repositories/lesson_repository.dart';
import '../domain/usecases/get_all_lessons.dart';
import '../domain/usecases/get_lesson_by_id.dart';
import '../domain/usecases/get_user_progress.dart';
import '../domain/usecases/update_lesson_progress.dart';
import '../presentation/bloc/lesson_bloc.dart';

/// Initialize learn feature dependencies
Future<void> initLearnDependencies() async {
  // Data sources
  sl.registerSingleton<LessonLocalDataSource>(MockLessonLocalDataSource());
  sl.registerSingleton<LessonRemoteDataSource>(
    MockLessonRemoteDataSource(
      localDataSource: sl.get<LessonLocalDataSource>(),
    ),
  );

  // Repositories
  sl.registerSingleton<LessonRepository>(
    LessonRepositoryImpl(
      remoteDataSource: sl.get<LessonRemoteDataSource>(),
      localDataSource: sl.get<LessonLocalDataSource>(),
      networkInfo: sl.get<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerSingleton<GetAllLessonsUseCase>(
    GetAllLessonsUseCase(sl.get<LessonRepository>()),
  );

  sl.registerSingleton<GetLessonByIdUseCase>(
    GetLessonByIdUseCase(sl.get<LessonRepository>()),
  );

  sl.registerSingleton<GetUserProgressUseCase>(
    GetUserProgressUseCase(sl.get<LessonRepository>()),
  );

  sl.registerSingleton<UpdateLessonProgressUseCase>(
    UpdateLessonProgressUseCase(sl.get<LessonRepository>()),
  );

  // BLoC
  sl.registerFactory<LessonBloc>(
    () => LessonBloc(
      getAllLessons: sl.get<GetAllLessonsUseCase>(),
      getLessonById: sl.get<GetLessonByIdUseCase>(),
      getUserProgress: sl.get<GetUserProgressUseCase>(),
      updateLessonProgress: sl.get<UpdateLessonProgressUseCase>(),
    ),
  );
}
