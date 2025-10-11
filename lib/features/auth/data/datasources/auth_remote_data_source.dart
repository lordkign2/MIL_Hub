import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Abstract datasource interface for authentication operations
abstract class AuthRemoteDataSource {
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  UserModel? getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  bool get isSignedIn;

  Future<void> sendPasswordResetEmail({required String email});

  Future<UserModel> updateUserProfile({String? displayName, String? photoUrl});

  Future<void> deleteAccount();
}

/// Firebase implementation of AuthRemoteDataSource
class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to create user');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to sign in');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthException('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to sign in with Google');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  @override
  UserModel? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Reload user to get updated data
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser!;

      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  String _mapFirebaseAuthExceptionMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
