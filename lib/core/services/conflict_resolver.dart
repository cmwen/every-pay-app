import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/category.dart';

enum ConflictAction { keepLocal, keepRemote, merged }

class ConflictResult<T> {
  final T winner;
  final ConflictAction action;

  const ConflictResult({required this.winner, required this.action});
}

/// Last-write-wins conflict resolver with device_id tiebreaker
/// and edit-beats-delete rule.
class ConflictResolver {
  const ConflictResolver();

  /// Resolve conflict between two expense records.
  /// Rules:
  /// 1. Edit beats delete (non-deleted wins over deleted)
  /// 2. Last-write-wins by updatedAt
  /// 3. Device ID tiebreaker (higher ID wins for determinism)
  ConflictResult<Expense> resolveExpense({
    required Expense local,
    required Expense remote,
    bool localDeleted = false,
    bool remoteDeleted = false,
  }) {
    // Rule 1: Edit beats delete
    if (localDeleted && !remoteDeleted) {
      return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
    }
    if (!localDeleted && remoteDeleted) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }

    // Rule 2: Last-write-wins
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
    }

    // Rule 3: Device ID tiebreaker
    if (local.deviceId.compareTo(remote.deviceId) >= 0) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }
    return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
  }

  /// Resolve conflict between two category records.
  ConflictResult<Category> resolveCategory({
    required Category local,
    required Category remote,
    bool localDeleted = false,
    bool remoteDeleted = false,
  }) {
    // Rule 1: Edit beats delete
    if (localDeleted && !remoteDeleted) {
      return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
    }
    if (!localDeleted && remoteDeleted) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }

    // Rule 2: Last-write-wins
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
    }

    // Rule 3: Device ID tiebreaker (categories don't have deviceId, use id)
    if (local.id.compareTo(remote.id) >= 0) {
      return ConflictResult(winner: local, action: ConflictAction.keepLocal);
    }
    return ConflictResult(winner: remote, action: ConflictAction.keepRemote);
  }
}
