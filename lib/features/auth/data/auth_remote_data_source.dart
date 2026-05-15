// lib/features/auth/data/auth_remote_data_source.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/services/logger_service.dart';
import '../../../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

/// Handles all Firebase Auth and Firestore user operations.
class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Current Firebase user (null if not authenticated).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const AuthException(message: 'Sign in failed.');

      // Fetch user profile from Firestore
      return await _fetchUserProfile(user.uid, user.email ?? email);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth sign in error', e);
      throw AuthException(message: _mapFirebaseAuthError(e.code), code: e.code);
    }
  }

  /// Create a new account with email and password.
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const AuthException(message: 'Sign up failed.');

      // Update display name if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Create user profile in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        totalScans: 0,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth sign up error', e);
      throw AuthException(message: _mapFirebaseAuthError(e.code), code: e.code);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.i('User signed out');
    } catch (e) {
      AppLogger.e('Sign out error', e);
      throw AuthException(message: 'Sign out failed: $e');
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code), code: e.code);
    }
  }

  /// Fetch user profile from Firestore, creating one if it doesn't exist.
  Future<UserModel> _fetchUserProfile(String uid, String email) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }

    // Auto-create profile if missing (first sign in after migration)
    final user = UserModel(uid: uid, email: email, createdAt: DateTime.now());
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toJson());
    return user;
  }

  /// Map Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Provider for the shared authentication remote data source.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);
