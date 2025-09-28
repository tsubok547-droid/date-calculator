// lib/repositories/history_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_state.dart';
import '../models/history_duplicate_policy.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

/// 計算履歴の永続化（保存・読み込み）に関する唯一の責務を担うクラス
class HistoryRepository {
  final SettingsService _settingsService;
  // SharedPreferencesのインスタンスを直接保持する
  late final SharedPreferences _prefs;

  HistoryRepository(this._settingsService);

  // 初期化メソッドを追加
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 履歴をすべて取得する
  Future<List<CalculationState>> getAll() async {
    final historyJson = _prefs.getStringList(PrefKeys.calcHistory) ?? [];
    try {
      return historyJson
          .map((json) => CalculationState.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // パースに失敗した場合は、壊れたデータを削除して空のリストを返す
      await _prefs.remove(PrefKeys.calcHistory);
      return [];
    }
  }

  /// 新しい計算結果を1件追加する
  Future<void> add(CalculationState newState) async {
    if (newState.finalDate == null) return;

    List<CalculationState> history = await getAll();
    final policy = _settingsService.getHistoryDuplicatePolicy();

    switch (policy) {
      case HistoryDuplicatePolicy.keepAll:
        break;
      case HistoryDuplicatePolicy.removeSameComment:
        if (newState.comment != null && newState.comment!.isNotEmpty) {
          history.removeWhere((item) => item.comment == newState.comment);
        }
        break;
      case HistoryDuplicatePolicy.removeSameCalculation:
        history.removeWhere((item) =>
            item.comment == newState.comment &&
            item.standardDate == newState.standardDate &&
            item.daysExpression == newState.daysExpression);
        break;
    }

    history.insert(0, newState);

    if (history.length > AppConstants.calculationHistoryLimit) {
      history.removeLast();
    }

    await _saveAll(history);
  }

  /// 履歴リスト全体を保存する（並べ替えやインポートで使用）
  Future<void> updateAll(List<CalculationState> history) async {
    await _saveAll(history);
  }

  /// 全履歴を削除する
  Future<void> clearAll() async {
    await _prefs.remove(PrefKeys.calcHistory);
  }

  /// 履歴リストをSharedPreferencesに書き込むプライベートメソッド
  Future<void> _saveAll(List<CalculationState> history) async {
    List<String> historyJson =
        history.map((state) => jsonEncode(state.toJson())).toList();
    await _prefs.setStringList(PrefKeys.calcHistory, historyJson);
  }
}