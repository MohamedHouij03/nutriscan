// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ─────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Firebase ──────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Firebase initialized');
  } catch (e) {
    AppLogger.e('Firebase initialization failed', e);
  }

  // ── Hive ────────────────────────────────────────────────
  try {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.scanHistoryBox);
    await Hive.openBox(AppConstants.settingsBox);
    AppLogger.i('Hive initialized');
  } catch (e) {
    AppLogger.e('Hive initialization failed', e);
  }

  runApp(const ProviderScope(child: NutriScanApp()));
}

class NutriScanApp extends ConsumerWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
