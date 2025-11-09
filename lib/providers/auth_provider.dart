import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  AppUser? _appUser;
  bool _isLoading = false;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      // Reload user to get latest email verification status
      await user.reload();
      _user = _auth.currentUser;
      await _loadUserData();
    } else {
      _appUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _appUser = AppUser.fromFirestore(doc);
        } else {
          // Create user document if it doesn't exist
          _appUser = AppUser(
            id: _user!.uid,
            email: _user!.email ?? '',
            displayName: _user!.displayName ?? 'User',
            emailVerified: _user!.emailVerified,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(_user!.uid).set(_appUser!.toFirestore());
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        // Fallback user data
        _appUser = AppUser(
          id: _user!.uid,
          email: _user!.email ?? '',
          displayName: _user!.displayName ?? 'User',
          emailVerified: _user!.emailVerified,
          createdAt: DateTime.now(),
        );
      }
    }
  }

  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('Attempting sign up with email: $email');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('Sign up successful, user: ${result.user?.uid}');

      if (result.user != null) {
        // Send verification email
        await result.user!.sendEmailVerification();
        
        // Update display name
        await result.user!.updateDisplayName(displayName);
        
        // Create user document
        AppUser newUser = AppUser(
          id: result.user!.uid,
          email: email.trim(),
          displayName: displayName,
          emailVerified: false,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toFirestore());
        
        // For testing, don't sign out immediately
        // TODO: Re-enable in production
        // await _auth.signOut();
        
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth signup error: ${e.code} - ${e.message}');
      return _getReadableError(e.code);
    } catch (e) {
      debugPrint('Unexpected signup error: $e');
      return 'Sign up failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return 'Unknown error occurred';
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('Attempting sign in with email: $email');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      debugPrint('Sign in successful, user: ${result.user?.uid}');
      
      if (result.user != null) {
        // Reload to get latest verification status
        await result.user!.reload();
        _user = _auth.currentUser;
        
        // For testing, skip email verification check
        // TODO: Re-enable email verification in production
        // if (!_user!.emailVerified) {
        //   debugPrint('Email not verified');
        //   return 'Please verify your email before signing in. Check your inbox.';
        // }
        
        await _loadUserData();
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      return _getReadableError(e.code);
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return 'Authentication failed. Please check your credentials.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  String _getReadableError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    if (_user != null && !_user!.emailVerified) {
      await _user!.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    if (_user != null) {
      await _user!.reload();
      _user = _auth.currentUser;
      await _loadUserData();
      notifyListeners();
    }
  }
}