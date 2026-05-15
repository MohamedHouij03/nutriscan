// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

/// Base class for all application failures.
/// Used with dartz Either<Failure, T> pattern.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Network / connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

/// API timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT_ERROR',
  });
}

/// Firebase / server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code = 'SERVER_ERROR',
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
  });
}

/// OCR processing failure
class OcrFailure extends Failure {
  const OcrFailure({
    super.message = 'Could not extract text from image. Please try again.',
    super.code = 'OCR_ERROR',
  });
}

/// NER / AI processing failure
class NerFailure extends Failure {
  const NerFailure({
    super.message = 'AI analysis failed. Please try again.',
    super.code = 'NER_ERROR',
  });
}

/// Empty result failure
class EmptyScanFailure extends Failure {
  const EmptyScanFailure({
    super.message = 'No text found in image. Try a clearer photo.',
    super.code = 'EMPTY_SCAN',
  });
}

/// Camera failure
class CameraFailure extends Failure {
  const CameraFailure({
    super.message = 'Camera unavailable. Please check permissions.',
    super.code = 'CAMERA_ERROR',
  });
}

/// Cache / local storage failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Local storage error. Data may not be saved.',
    super.code = 'CACHE_ERROR',
  });
}
