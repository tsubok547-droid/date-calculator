// lib/repositories/history_repository.dart

import '../models/calculation_state.dart';
import '../models/history_duplicate_policy.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

/// 計算履歴の永続化（保存・読み込み）に関する責務を担うクラス
class HistoryRepository {
  final SettingsService _settingsService;

  HistoryRepository(this._settingsService);

  /// 新しい計算結果を履歴に保存する
  Future<void> save(CalculationState newState) async {
    // 保存する価値がない場合は何もしない (最終日がないなど)
    if (newState.finalDate == null) return;

    List<CalculationState> history = _settingsService.getHistory();
    final policy = _settingsService.getHistoryDuplicatePolicy();

    // --- ▼▼▼ ここからが `CalculatorNotifier` から移動してきたロジック ▼▼▼ ---
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
    // --- ▲▲▲ ここまで ▲▲▲ ---

    await _settingsService.saveHistory(history);
  }
}