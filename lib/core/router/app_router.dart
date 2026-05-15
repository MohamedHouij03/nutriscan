import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/scan/presentation/screens/home_screen.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/scan/presentation/screens/result_screen.dart';
import '../../models/scan_result_model.dart';
import '../constants/app_constants.dart';
import 'splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,

    redirect: (context, state) {
      final location = state.matchedLocation;

      final isAuthPage =
          location == AppRoutes.login || location == AppRoutes.signup;

      // ── LOADING STATE FIX ─────────────────────────────
      if (auth.isLoading && !auth.hasValue) {
        return AppRoutes.splash;
      }

      final isLoggedIn = auth.valueOrNull != null;

      // ── NOT LOGGED IN ────────────────────────────────
      if (!isLoggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      // ── LOGGED IN ─────────────────────────────────────
      if (isLoggedIn && (isAuthPage || location == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: AppRoutes.scan, builder: (_, __) => const ScanScreen()),
      GoRoute(
        path: AppRoutes.result,
        builder: (ctx, state) {
          final result = state.extra as ScanResultModel?;
          return result != null
              ? ResultScreen(result: result)
              : const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
    ],
  );
});
