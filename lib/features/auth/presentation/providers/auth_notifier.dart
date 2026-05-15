// lib/features/auth/presentation/providers/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../../domain/auth_repository.dart';

/// State class for authentication.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final Failure? failure;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.failure,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    Failure? failure,
    bool clearUser = false,
    bool clearFailure = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

/// StateNotifier that manages authentication business logic.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Sign in user with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _repository.signIn(email: email, password: password);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user, clearFailure: true);
        return true;
      },
    );
  }

  /// Create new account.
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user, clearFailure: true);
        return true;
      },
    );
  }

  /// Sign out current user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthState(); // Reset to initial
  }

  /// Send password reset email.
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _repository.sendPasswordReset(email);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, clearFailure: true);
        return true;
      },
    );
  }

  /// Clear any stored failure.
  void clearError() {
    state = state.copyWith(clearFailure: true);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
