// lib/features/auth/domain/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/services/logger_service.dart';
import '../../../models/user_model.dart';
import '../data/auth_remote_data_source.dart';

class AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepository(this._dataSource);

  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  Future<Either<Failure, UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } catch (e) {
      AppLogger.e('Sign in error', e);
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserModel>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _dataSource.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Right(user);
    } catch (e) {
      AppLogger.e('Sign up error', e);
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Password reset error', e);
      return Left(AuthFailure(message: e.toString()));
    }
  }
}

/// Provider for the auth repository.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(authRemoteDataSourceProvider)),
);

/// Provider exposing the current Firebase auth state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
