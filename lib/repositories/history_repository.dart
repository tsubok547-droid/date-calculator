// lib/repositories/history_repository.dart

import 'package:drift/drift.dart';

import '../data/database.dart';
import '../models/calculation_state.dart';
import '../models/history_duplicate_policy.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

/// 計算履歴の永続化を担うクラス（データベース版）
class HistoryRepository {
  final AppDatabase _db;
  final SettingsService _settingsService;

  HistoryRepository(this._db, this._settingsService);

  /// 履歴をすべて取得する (新しいものが先頭になるように)
  Future<List<CalculationState>> getAll() async {
    final query = _db.select(_db.calculationHistories)
      ..orderBy(
          [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]);
    final historyEntries = await query.get();
    return historyEntries.map(_mapToCalculationState).toList();
  }

  /// 新しい計算結果を1件追加する
  Future<void> add(CalculationState newState) async {
    if (newState.finalDate == null) return;

    final policy = _settingsService.getHistoryDuplicatePolicy();

    switch (policy) {
      case HistoryDuplicatePolicy.keepAll:
        break;
      case HistoryDuplicatePolicy.removeSameComment:
        if (newState.comment != null && newState.comment!.isNotEmpty) {
          await (_db.delete(_db.calculationHistories)
                ..where((tbl) => tbl.comment.equals(newState.comment!)))
              .go();
        }
        break;
      case HistoryDuplicatePolicy.removeSameCalculation:
        final statement = _db.delete(_db.calculationHistories);
        statement.where((tbl) {
          final standardChecks = tbl.standardDate.equals(newState.standardDate) &
              tbl.daysExpression.equals(newState.daysExpression);
          if (newState.comment != null) {
            return standardChecks & tbl.comment.equals(newState.comment!);
          } else {
            return standardChecks & tbl.comment.isNull();
          }
        });
        await statement.go();
        break;
    }

    await _db.into(_db.calculationHistories).insert(_mapToCompanion(newState));

    final idCount = _db.calculationHistories.id.count();
    final query = _db.selectOnly(_db.calculationHistories)..addColumns([idCount]);
    final result = await query.getSingle();
    final totalRows = result.read(idCount) ?? 0;

    if (totalRows > AppConstants.calculationHistoryLimit) {
      final oldestQuery = _db.select(_db.calculationHistories)
        ..orderBy(
            [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc)])
        ..limit(1);
      final oldest = await oldestQuery.getSingle();
      await (_db.delete(_db.calculationHistories)
            ..where((tbl) => tbl.id.equals(oldest.id)))
          .go();
    }
  }

  /// 履歴をマージする（重複データは無視する）
  /// @return 追加された件数
  Future<int> mergeHistory(List<CalculationState> history) async {
    var addedCount = 0;
    await _db.transaction(() async {
      for (final item in history) {
        final query = _db.select(_db.calculationHistories)
          ..where((tbl) {
            final standardChecks = tbl.standardDate.equals(item.standardDate) &
                tbl.daysExpression.equals(item.daysExpression);
            if (item.comment != null) {
              return standardChecks & tbl.comment.equals(item.comment!);
            } else {
              return standardChecks & tbl.comment.isNull();
            }
          });

        final existing = await query.getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.calculationHistories).insert(_mapToCompanion(item));
          addedCount++;
        }
      }
    });
    return addedCount;
  }

  /// 履歴リスト全体を保存する（並べ替えやインポートで使用）
  Future<void> updateAll(List<CalculationState> history) async {
    await _db.transaction(() async {
      await _db.delete(_db.calculationHistories).go();
      await _db.batch((batch) {
        batch.insertAll(
            _db.calculationHistories, history.map(_mapToCompanion));
      });
    });
  }

  /// 全履歴を削除する
  Future<void> clearAll() async {
    await _db.delete(_db.calculationHistories).go();
  }

  // --- データ変換用のヘルパーメソッド ---

  CalculationHistoriesCompanion _mapToCompanion(CalculationState state) {
    return CalculationHistoriesCompanion(
      standardDate: Value(state.standardDate),
      daysExpression: Value(state.daysExpression),
      finalDate: Value(state.finalDate),
      comment: Value(state.comment),
    );
  }

  CalculationState _mapToCalculationState(CalculationHistory entry) {
    return CalculationState(
      standardDate: entry.standardDate,
      daysExpression: entry.daysExpression,
      finalDate: entry.finalDate,
      comment: entry.comment,
    );
  }
}