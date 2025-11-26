import '../../../core/di/service_locator.dart';
import '../../../core/network/network_info.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_auth_state_stream.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up_with_email.dart';
import '../presentation/bloc/auth_bloc.dart';

/// Initialize authentication feature dependencies
Future<void> initAuthDependencies() async {
  // Data sources
  sl.registerSingleton<AuthRemoteDataSource>(FirebaseAuthDataSource());

  // Repositories
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: sl.get<AuthRemoteDataSource>(),
      networkInfo: sl.get<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerSingleton<SignUpWithEmailUseCase>(
    SignUpWithEmailUseCase(sl.get<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithEmailUseCase>(
    SignInWithEmailUseCase(sl.get<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithGoogleUseCase>(
    SignInWithGoogleUseCase(sl.get<AuthRepository>()),
  );

  sl.registerSingleton<SignOutUseCase>(
    SignOutUseCase(sl.get<AuthRepository>()),
  );

  sl.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(sl.get<AuthRepository>()),
  );

  sl.registerSingleton<GetAuthStateStreamUseCase>(
    GetAuthStateStreamUseCase(sl.get<AuthRepository>()),
  );

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signUpWithEmail: sl.get<SignUpWithEmailUseCase>(),
      signInWithEmail: sl.get<SignInWithEmailUseCase>(),
      signInWithGoogle: sl.get<SignInWithGoogleUseCase>(),
      signOut: sl.get<SignOutUseCase>(),
      getCurrentUser: sl.get<GetCurrentUserUseCase>(),
      getAuthStateStream: sl.get<GetAuthStateStreamUseCase>(),
    ),
  );
}
