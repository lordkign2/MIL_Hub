import 'package:get_it/get_it.dart';
import '../domain/repositories/link_check_repository.dart';
import '../domain/usecases/analyze_link_usecase.dart';
import '../domain/usecases/save_link_check_usecase.dart';
import '../domain/usecases/get_recent_link_checks_usecase.dart';
import '../domain/usecases/get_user_link_checks_usecase.dart';
import '../domain/usecases/find_previous_check_usecase.dart';
import '../domain/usecases/check_image_authenticity_usecase.dart';
import '../data/repositories/link_check_repository_impl.dart';
import '../data/datasources/link_check_remote_datasource.dart';
import '../presentation/bloc/check_bloc.dart';

final checkSl = GetIt.instance;

Future<void> initCheckDependencies() async {
  // Data sources
  checkSl.registerLazySingleton<LinkCheckRemoteDataSource>(
    () => LinkCheckRemoteDataSourceImpl(),
  );

  // Repositories
  checkSl.registerLazySingleton<LinkCheckRepository>(
    () => LinkCheckRepositoryImpl(remoteDataSource: checkSl()),
  );

  // Use cases
  checkSl.registerLazySingleton(() => AnalyzeLinkUseCase(checkSl()));
  checkSl.registerLazySingleton(() => SaveLinkCheckUseCase(checkSl()));
  checkSl.registerLazySingleton(() => GetRecentLinkChecksUseCase(checkSl()));
  checkSl.registerLazySingleton(() => GetUserLinkChecksUseCase(checkSl()));
  checkSl.registerLazySingleton(() => FindPreviousCheckUseCase(checkSl()));
  checkSl.registerLazySingleton(() => CheckImageAuthenticityUseCase(checkSl()));

  // Bloc
  checkSl.registerFactory(
    () => CheckBloc(
      analyzeLinkUseCase: checkSl(),
      saveLinkCheckUseCase: checkSl(),
      getRecentLinkChecksUseCase: checkSl(),
      getUserLinkChecksUseCase: checkSl(),
      findPreviousCheckUseCase: checkSl(),
    ),
  );
}
