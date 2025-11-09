import "package:firebase_auth/firebase_auth.dart";

/// Service class that handles all Firebase Authentication operations
/// Provides methods for signup, signin, email verification, and signout
class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently authenticated user, null if not signed in
  User? get currentUser => _auth.currentUser;
  
  /// Stream that emits auth state changes (login/logout events)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a new user account with email and password
  /// Automatically sends email verification after successful signup
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    // Create user account in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send email verification to the new user
    await userCredential.user?.sendEmailVerification();

    return userCredential;
  }

  /// Signs in an existing user with email and password
  /// Returns UserCredential on successful authentication
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return userCredential;
  }

  /// Resends email verification to the current user
  /// Only sends if user exists and email is not already verified
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Checks if the current user's email is verified
  /// Reloads user data from server to get latest verification status
  Future<bool> isEmailVerified() async {
    // Reload user data to get latest verification status
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Signs out the current user
  /// Clears authentication state and returns to welcome screen
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
