// lib/providers/history_management_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../controllers/calculator_page_controller.dart';
import '../models/calculation_state.dart';
import '../services/history_service.dart';
import 'history_provider.dart';

part 'history_management_provider.g.dart';

@riverpod
class HistoryManagementNotifier extends _$HistoryManagementNotifier {
  final _historyService = HistoryService();

  @override
  void build() {}

  Future<String> exportHistory() async {
    final currentHistory = ref.read(historyNotifierProvider).valueOrNull;

    if (currentHistory == null || currentHistory.isEmpty) {
      return 'エクスポートする履歴がありません。';
    }

    final success = await _historyService.exportHistory(currentHistory);
    return success ? '履歴を共有しました。' : 'エクスポートに失敗しました。';
  }

  Future<List<CalculationState>?> getImportedHistoryData() async {
    return await _historyService.importHistory();
  }

  Future<String> saveImportedHistory(
    List<CalculationState> history,
    ImportAction action,
  ) async {
    final notifier = ref.read(historyNotifierProvider.notifier);
    if (action == ImportAction.replace) {
      await notifier.replaceAll(history);
      return '${history.length}件の履歴をインポート（上書き）しました。';
    } else {
      final addedCount = await notifier.merge(history);
      // 不要な ${} を削除
      return '$history.length件中、$addedCount件の新しい履歴をマージしました。';
    }
  }
}