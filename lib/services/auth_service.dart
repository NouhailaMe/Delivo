import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// SIGN UP + SEND EMAIL VERIFICATION
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    final UserCredential cred =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null && !cred.user!.emailVerified) {
      await cred.user!.sendEmailVerification();
    }

    return cred.user;
  }

  /// SIGN IN (THROWS PRECISE FIREBASE ERROR CODES)
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential cred =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found',
      );
    }

    // 🔄 Force server refresh
    await user.getIdToken(true);
    await user.reload();

    final User? refreshedUser = _auth.currentUser;

    if (refreshedUser == null || !refreshedUser.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email not verified',
      );
    }

    return refreshedUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
