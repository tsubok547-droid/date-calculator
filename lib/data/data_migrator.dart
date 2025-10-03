// lib/data/data_migrator.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../models/calculation_state.dart';
import '../utils/constants.dart';
import 'database.dart';

class DataMigrator {
  static const _migrationFlagKey = 'db_migration_complete';

  /// 必要であれば、SharedPreferencesからDriftデータベースへデータ移行を行う
  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 既に移行が完了しているかチェック
    if (prefs.getBool(_migrationFlagKey) ?? false) {
      // 完了済みなら何もしない
      return;
    }

    // 2. 古い履歴データをSharedPreferencesから読み込む
    final oldHistoryJson = prefs.getStringList(PrefKeys.calcHistory) ?? [];
    if (oldHistoryJson.isEmpty) {
      // 古いデータがなければ、移行完了フラグだけ立てて終了
      await prefs.setBool(_migrationFlagKey, true);
      return;
    }

    // 3. 読み込んだデータをアプリで使える形式に変換
    final List<CalculationState> oldHistory = oldHistoryJson
        .map((json) => CalculationState.fromJson(jsonDecode(json)))
        .toList();

    // 4. 新しいデータベースに全件を保存
    final db = AppDatabase();
    await db.batch((batch) {
      batch.insertAll(
        db.calculationHistories,
        oldHistory.map((state) => CalculationHistoriesCompanion.insert(
              standardDate: state.standardDate,
              daysExpression: state.daysExpression,
              finalDate: Value(state.finalDate),
              comment: Value(state.comment),
            )),
      );
    });

    // 5. 移行が完了したことを記録する
    await prefs.setBool(_migrationFlagKey, true);

    // 6. (任意) SharedPreferencesから古い履歴データを削除して容量を節約
    await prefs.remove(PrefKeys.calcHistory);
  }
}