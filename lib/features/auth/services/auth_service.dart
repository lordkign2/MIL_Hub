import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final User? user;
  final String? error;
  AuthResult({this.user, this.error});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Email signup
  Future<AuthResult> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return AuthResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(error: e.message ?? "Signup failed");
    } catch (e) {
      return AuthResult(error: "Unexpected error: $e");
    }
  }

  // Email login
  Future<AuthResult> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return AuthResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(error: e.message ?? "Login failed");
    } catch (e) {
      return AuthResult(error: "Unexpected error: $e");
    }
  }

  // Google login
  Future<User?> signInWithGoogle() async {
  try {
    // Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User canceled login

    // Get auth details from Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in with Firebase
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCredential.user;
  } catch (e) {
    print("Google Sign-In Error: $e");
    return null;
  }
}


  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Auth state
  Stream<User?> get userChanges => _auth.authStateChanges();
}

