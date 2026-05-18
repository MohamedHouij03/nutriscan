// lib/features/scan/data/scan_repository.dart
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../core/errors/failures.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/ner_api_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../models/scan_result_model.dart';

/// Repository handling the full scan pipeline:
/// Image → OCR → NER API → Firestore → Result
class ScanRepository {
  final OcrService _ocrService;
  final NerApiService _nerService;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final Uuid _uuid = const Uuid();

  ScanRepository({
    required OcrService ocrService,
    required NerApiService nerService,
    required ConnectivityService connectivity,
    FirebaseFirestore? firestore,
  })  : _ocrService = ocrService,
        _nerService = nerService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity;

  /// Full scan pipeline: image → OCR → NER → save → return result.
  /// Wrapped in a timeout to prevent the UI from hanging forever.
  Future<Either<Failure, ScanResultModel>> performScan(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    try {
      return await _performScanInternal(imageBytes, imagePath: imagePath)
          .timeout(AppConstants.apiTimeout, onTimeout: () {
        AppLogger.e(
            'Scan pipeline timed out after ${AppConstants.apiTimeout.inSeconds}s');
        return const Left(ServerFailure(
          message:
              'Scan timed out. Please check your connection and try again.',
        ));
      });
    } on app_exceptions.OcrException catch (e) {
      return Left(OcrFailure(message: e.message));
    } on app_exceptions.NerException catch (e) {
      return Left(NerFailure(message: e.message));
    } catch (e, st) {
      AppLogger.e('Unexpected scan error', e, st);
      return Left(ServerFailure(message: 'Scan failed: $e'));
    }
  }

  /// Internal scan pipeline implementation.
  Future<Either<Failure, ScanResultModel>> _performScanInternal(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    // ── Step 0: Auth check ──────────────────────────────────────────────────
    // Use FirebaseAuth directly — works offline with cached credentials.
    // Avoids calling Firestore which hangs when offline.
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated.'));
    }

    // ── Step 1: OCR ─────────────────────────────────────────────────────────
    AppLogger.i('Step 1: Running OCR');
    final String extractedText;
    try {
      extractedText = await _ocrService
          .extractText(
        imageBytes,
        imagePath: imagePath,
      )
          .timeout(AppConstants.ocrTimeout, onTimeout: () {
        throw const app_exceptions.OcrException(
          'OCR timed out. The image may be too large or the server is busy.',
        );
      });
    } on app_exceptions.OcrException catch (e) {
      return Left(OcrFailure(message: e.message));
    }

    if (extractedText.trim().isEmpty) {
      return const Left(EmptyScanFailure());
    }

    // ── Step 2: NER (AI) ────────────────────────────────────────────────────
    AppLogger.i('Step 2: Running NER analysis');
    late final NerResponseModel nerResponse;
    final hasConnection = await _connectivity.hasConnection();

    if (hasConnection) {
      try {
        nerResponse = await _nerService.analyzeIngredients(extractedText);
      } on app_exceptions.NerException {
        // Fallback to local keyword analysis
        AppLogger.w('NER API failed, using local fallback');
        nerResponse = _nerService.analyzeLocally(extractedText);
      } on app_exceptions.NetworkException {
        AppLogger.w('Network error in NER, using local fallback');
        nerResponse = _nerService.analyzeLocally(extractedText);
      } on app_exceptions.TimeoutException {
        AppLogger.w('NER API timed out, using local fallback');
        nerResponse = _nerService.analyzeLocally(extractedText);
      }
    } else {
      AppLogger.w('No internet, using local NER fallback');
      nerResponse = _nerService.analyzeLocally(extractedText);
    }

    // ── Step 3: Build result ────────────────────────────────────────────────
    final result = ScanResultModel(
      id: _uuid.v4(),
      userId: userId,
      extractedText: extractedText,
      allergens: nerResponse.allergens,
      additives: nerResponse.additives,
      confidence: nerResponse.confidence,
      timestamp: DateTime.now(),
    );

    // ── Step 4: Persist to Firestore ────────────────────────────────────────
    // Non-blocking: don't fail the scan if Firestore is unavailable.
    AppLogger.i('Step 3: Saving scan to Firestore');
    if (hasConnection) {
      try {
        await _saveScanToFirestore(result).timeout(const Duration(seconds: 10),
            onTimeout: () {
          AppLogger.w('Firestore save timed out - scan result not saved');
        });
      } catch (e) {
        AppLogger.w('Failed to save to Firestore: $e');
        // Don't fail the scan if storage fails
      }
    } else {
      AppLogger.i('Offline - scan result not saved to cloud');
    }

    AppLogger.i(
        'Scan complete: ${result.allergens.length} allergens, ${result.additives.length} additives');
    return Right(result);
  }

  /// Save scan result to Firestore under user's sub-collection.
  Future<void> _saveScanToFirestore(ScanResultModel result) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(result.userId)
        .collection(AppConstants.historySubCollection)
        .doc(result.id);

    await docRef.set(result.toFirestore());

    // Also increment user's total scan count
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(result.userId)
        .update({'total_scans': FieldValue.increment(1)});
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepository(
    ocrService: ref.read(ocrServiceProvider),
    nerService: ref.read(nerApiServiceProvider),
    connectivity: ref.read(connectivityServiceProvider),
  ),
);
