import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  Future<({UserEntity? user, Failure? failure})> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<({UserEntity? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<({UserEntity? user, Failure? failure})> signInWithGoogle();

  /// Sign out current user
  Future<({bool success, Failure? failure})> signOut();

  /// Get current user
  UserEntity? getCurrentUser();

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Check if user is signed in
  bool get isSignedIn;

  /// Send password reset email
  Future<({bool success, Failure? failure})> sendPasswordResetEmail({
    required String email,
  });

  /// Update user profile
  Future<({UserEntity? user, Failure? failure})> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete user account
  Future<({bool success, Failure? failure})> deleteAccount();
}
