import '../../domain/entities/user_entity.dart';

/// Base class for all authentication events
abstract class AuthEvent {
  const AuthEvent();
}

/// Event to sign up with email and password
class SignUpWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignUpWithEmailEvent({required this.email, required this.password});
}

/// Event to sign in with email and password
class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailEvent({required this.email, required this.password});
}

/// Event to sign in with Google
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Event to sign out
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

/// Event to check authentication status
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Event triggered when auth state changes
class AuthStateChangedEvent extends AuthEvent {
  final UserEntity? user;

  const AuthStateChangedEvent(this.user);
}

/// Event to send password reset email
class SendPasswordResetEvent extends AuthEvent {
  final String email;

  const SendPasswordResetEvent({required this.email});
}
