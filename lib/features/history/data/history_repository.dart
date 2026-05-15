// lib/features/history/data/history_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/logger_service.dart';
import '../../../models/scan_result_model.dart';
import '../../auth/data/auth_remote_data_source.dart';
import '../../auth/domain/auth_repository.dart';

/// Repository for fetching and deleting scan history from Firestore.
class HistoryRepository {
  final FirebaseFirestore _firestore;
  final AuthRemoteDataSource _auth;

  HistoryRepository({
    required AuthRemoteDataSource auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch paginated scan history for the current user.
  Future<Either<Failure, List<ScanResultModel>>> getHistory({
    int limit = AppConstants.historyPageSize,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return const Left(AuthFailure(message: 'User not authenticated.'));
      }

      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.historySubCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final scans = snapshot.docs
          .map((doc) => ScanResultModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      return Right(scans);
    } on FirebaseException catch (e) {
      AppLogger.e('Firestore history fetch error', e);
      return Left(
          ServerFailure(message: e.message ?? 'Failed to load history.'));
    } catch (e, st) {
      AppLogger.e('Unexpected history error', e, st);
      return Left(ServerFailure(message: 'Failed to load history: $e'));
    }
  }

  /// Stream of recent scans (real-time updates).
  Stream<List<ScanResultModel>> watchHistory({int limit = 10}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.historySubCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScanResultModel.fromJson(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  /// Delete a specific scan from history.
  Future<Either<Failure, void>> deleteScan(String scanId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return const Left(AuthFailure(message: 'User not authenticated.'));
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.historySubCollection)
          .doc(scanId)
          .delete();

      // Decrement scan count
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'total_scans': FieldValue.increment(-1)});

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete scan: $e'));
    }
  }

  /// Get aggregate stats for the dashboard.
  Future<Either<Failure, ScanStats>> getScanStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return const Right(ScanStats.empty());
      }

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.historySubCollection)
          .get();

      int totalAllergens = 0;
      int totalAdditives = 0;
      final allergenCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final scan = ScanResultModel.fromJson(doc.data(), doc.id);
        totalAllergens += scan.allergens.length;
        totalAdditives += scan.additives.length;
        for (final allergen in scan.allergens) {
          allergenCounts[allergen.name] =
              (allergenCounts[allergen.name] ?? 0) + 1;
        }
      }

      return Right(ScanStats(
        totalScans: snapshot.docs.length,
        totalAllergens: totalAllergens,
        totalAdditives: totalAdditives,
        allergenCounts: allergenCounts,
      ));
    } catch (e) {
      AppLogger.e('Stats error', e);
      return const Right(ScanStats.empty());
    }
  }
}

/// Aggregated statistics for the home dashboard.
class ScanStats {
  final int totalScans;
  final int totalAllergens;
  final int totalAdditives;
  final Map<String, int> allergenCounts;

  const ScanStats({
    required this.totalScans,
    required this.totalAllergens,
    required this.totalAdditives,
    required this.allergenCounts,
  });

  const ScanStats.empty()
      : totalScans = 0,
        totalAllergens = 0,
        totalAdditives = 0,
        allergenCounts = const {};
}

// ─── Providers ────────────────────────────────────────────────────────────────

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(
    auth: ref.read(authRemoteDataSourceProvider),
  ),
);

/// Stream provider for real-time history updates.
final historyStreamProvider = StreamProvider<List<ScanResultModel>>((ref) {
  return ref.read(historyRepositoryProvider).watchHistory();
});

/// Future provider for stats.
final scanStatsProvider = FutureProvider<ScanStats>((ref) {
  return ref
      .read(historyRepositoryProvider)
      .getScanStats()
      .then((e) => e.fold((_) => const ScanStats.empty(), (s) => s));
});
