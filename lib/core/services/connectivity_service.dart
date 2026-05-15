// lib/core/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to check and monitor network connectivity.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if the device currently has internet access.
  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream of connectivity changes.
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}

/// Provider for ConnectivityService.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Provider for current connectivity status (async).
final isConnectedProvider = FutureProvider<bool>(
  (ref) => ref.read(connectivityServiceProvider).hasConnection(),
);

/// Provider streaming connectivity changes.
final connectivityStreamProvider = StreamProvider<bool>(
  (ref) => ref.read(connectivityServiceProvider).connectivityStream,
);
