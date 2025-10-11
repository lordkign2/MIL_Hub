import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/get_auth_state_stream.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for handling authentication logic
class AuthBloc {
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignInWithEmailUseCase _signInWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  final GetAuthStateStreamUseCase _getAuthStateStream;

  // State management
  AuthState _state = const AuthInitial();
  final _stateController = StreamController<AuthState>.broadcast();

  // Event handling
  final _eventController = StreamController<AuthEvent>();
  late StreamSubscription _eventSubscription;
  late StreamSubscription _authStateSubscription;

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
       _getAuthStateStream = getAuthStateStream {
    // Initialize event handling
    _eventSubscription = _eventController.stream.listen(_handleEvent);

    // Listen to auth state changes
    _authStateSubscription = _getAuthStateStream().listen((user) {
      add(AuthStateChangedEvent(user));
    });

    // Check initial auth status
    add(const CheckAuthStatusEvent());
  }

  /// Current state
  AuthState get state => _state;

  /// State stream
  Stream<AuthState> get stream => _stateController.stream;

  /// Add event
  void add(AuthEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Handle events
  Future<void> _handleEvent(AuthEvent event) async {
    try {
      if (event is SignUpWithEmailEvent) {
        await _handleSignUpWithEmail(event);
      } else if (event is SignInWithEmailEvent) {
        await _handleSignInWithEmail(event);
      } else if (event is SignInWithGoogleEvent) {
        await _handleSignInWithGoogle(event);
      } else if (event is SignOutEvent) {
        await _handleSignOut(event);
      } else if (event is CheckAuthStatusEvent) {
        await _handleCheckAuthStatus(event);
      } else if (event is AuthStateChangedEvent) {
        await _handleAuthStateChanged(event);
      }
    } catch (e) {
      _emitState(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _handleSignUpWithEmail(SignUpWithEmailEvent event) async {
    _emitState(const AuthLoading());

    final result = await _signUpWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.user != null) {
      _emitState(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      _emitState(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _handleSignInWithEmail(SignInWithEmailEvent event) async {
    _emitState(const AuthLoading());

    final result = await _signInWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.user != null) {
      _emitState(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      _emitState(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _handleSignInWithGoogle(SignInWithGoogleEvent event) async {
    _emitState(const AuthLoading());

    final result = await _signInWithGoogle();

    if (result.user != null) {
      _emitState(AuthAuthenticated(user: result.user!));
    } else if (result.failure != null) {
      _emitState(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _handleSignOut(SignOutEvent event) async {
    _emitState(const AuthLoading());

    final result = await _signOut();

    if (result.success) {
      _emitState(const AuthUnauthenticated());
    } else if (result.failure != null) {
      _emitState(AuthError(message: result.failure!.message));
    }
  }

  Future<void> _handleCheckAuthStatus(CheckAuthStatusEvent event) async {
    final user = _getCurrentUser();

    if (user != null) {
      _emitState(AuthAuthenticated(user: user));
    } else {
      _emitState(const AuthUnauthenticated());
    }
  }

  Future<void> _handleAuthStateChanged(AuthStateChangedEvent event) async {
    if (event.user != null) {
      _emitState(AuthAuthenticated(user: event.user!));
    } else {
      _emitState(const AuthUnauthenticated());
    }
  }

  void _emitState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription.cancel();
    _authStateSubscription.cancel();
    _eventController.close();
    _stateController.close();
  }
}
