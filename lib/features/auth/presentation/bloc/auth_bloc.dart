import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_auth_state_stream.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for handling authentication logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignInWithEmailUseCase _signInWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  final GetAuthStateStreamUseCase _getAuthStateStream;

  AuthBloc({
    required SignUpWithEmailUseCase signUpWithEmail,
    required SignInWithEmailUseCase signInWithEmail,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
    required GetAuthStateStreamUseCase getAuthStateStream,
  }) : _signUpWithEmail = signUpWithEmail,
       _signInWithEmail = signInWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _getAuthStateStream = getAuthStateStream,
       super(const AuthInitial()) {
    on<SignUpWithEmailEvent>(_onSignUpWithEmail);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<AuthStateChangedEvent>(_onAuthStateChanged);

    // Listen to auth state changes
    _getAuthStateStream().listen((user) {
      add(AuthStateChangedEvent(user));
    });

    // Check initial auth status
    add(const CheckAuthStatusEvent());
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signUpWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      emit(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      emit(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithGoogle();

    if (result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      emit(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await _signOut();

    if (result.success) {
      emit(const AuthUnauthenticated());
    } else if (result.failure != null) {
      emit(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = _getCurrentUser();

    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}
