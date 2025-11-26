import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to sign up with email and password
class SignUpWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignUpWithEmailEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign in with email and password
class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign in with Google
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();

  @override
  List<Object?> get props => [];
}

/// Event to sign out
class SignOutEvent extends AuthEvent {
  const SignOutEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when auth state changes
class AuthStateChangedEvent extends AuthEvent {
  final UserEntity? user;

  const AuthStateChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}

/// Event to send password reset email
class SendPasswordResetEvent extends AuthEvent {
  final String email;

  const SendPasswordResetEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
