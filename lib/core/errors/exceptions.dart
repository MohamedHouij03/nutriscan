// lib/core/errors/exceptions.dart

/// Custom exception classes thrown in data layer,
/// then mapped to Failures in repository layer.
library;


class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection.']);
  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out.']);
  @override
  String toString() => 'TimeoutException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException({required this.message, this.code});
  @override
  String toString() => 'AuthException($code): $message';
}

class OcrException implements Exception {
  final String message;
  const OcrException([this.message = 'OCR processing failed.']);
  @override
  String toString() => 'OcrException: $message';
}

class NerException implements Exception {
  final String message;
  const NerException([this.message = 'NER processing failed.']);
  @override
  String toString() => 'NerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache error.']);
  @override
  String toString() => 'CacheException: $message';
}

class CameraException implements Exception {
  final String message;
  const CameraException([this.message = 'Camera error.']);
  @override
  String toString() => 'CameraException: $message';
}
