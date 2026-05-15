// lib/features/scan/presentation/providers/scan_notifier.dart
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/scan_result_model.dart';
import '../../data/scan_repository.dart';

/// Represents the different states of a scan operation.
enum ScanStep { idle, takingPhoto, extractingText, analyzingAI, saving, done }

/// Scan state encapsulating progress + result.
class ScanState {
  final ScanStep step;
  final ScanResultModel? result;
  final Failure? failure;
  final Uint8List? capturedImage;

  const ScanState({
    this.step = ScanStep.idle,
    this.result,
    this.failure,
    this.capturedImage,
  });

  bool get isLoading =>
      step != ScanStep.idle && step != ScanStep.done && failure == null;
  bool get hasError => failure != null;
  bool get isDone => step == ScanStep.done && result != null;

  /// User-facing progress message.
  String get progressMessage {
    switch (step) {
      case ScanStep.takingPhoto:
        return 'Capturing image...';
      case ScanStep.extractingText:
        return 'Reading ingredient text...';
      case ScanStep.analyzingAI:
        return 'AI analyzing ingredients...';
      case ScanStep.saving:
        return 'Saving results...';
      case ScanStep.done:
        return 'Analysis complete!';
      default:
        return '';
    }
  }

  ScanState copyWith({
    ScanStep? step,
    ScanResultModel? result,
    Failure? failure,
    Uint8List? capturedImage,
    bool clearFailure = false,
    bool clearResult = false,
  }) {
    return ScanState(
      step: step ?? this.step,
      result: clearResult ? null : result ?? this.result,
      failure: clearFailure ? null : failure ?? this.failure,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

/// Notifier managing the scan workflow.
class ScanNotifier extends StateNotifier<ScanState> {
  final ScanRepository _repository;

  ScanNotifier(this._repository) : super(const ScanState());

  /// Start full scan pipeline from image bytes.
  Future<void> startScan(Uint8List imageBytes, {String? imagePath}) async {
    // Reset state
    state = ScanState(
      step: ScanStep.extractingText,
      capturedImage: imageBytes,
    );

    // Progress through pipeline steps with UI feedback
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(step: ScanStep.extractingText);

    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(step: ScanStep.analyzingAI);

    // Actually run the scan
    final result = await _repository.performScan(
      imageBytes,
      imagePath: imagePath,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          step: ScanStep.idle,
          failure: failure,
        );
      },
      (scanResult) {
        state = state.copyWith(
          step: ScanStep.done,
          result: scanResult,
          clearFailure: true,
        );
      },
    );
  }

  /// Reset scan state (go back to idle).
  void reset() {
    state = const ScanState();
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearFailure: true, step: ScanStep.idle);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(ref.read(scanRepositoryProvider)),
);
