// lib/providers/history_management_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/calculation_state.dart';
import '../services/history_service.dart';
import 'history_provider.dart';

part 'history_management_provider.g.dart';

@riverpod
class HistoryManagementNotifier extends _$HistoryManagementNotifier {
  final _historyService = HistoryService();

  @override
  void build() {
    // このNotifierは状態を持たず、メソッドの実行のみを目的とするため、buildメソッドは空です。
  }

  /// 履歴をCSVとしてエクスポートする
  Future<String> exportHistory() async {
    // ▼▼▼ ここを修正 ▼▼▼
    // .valueOrNullを使って、AsyncValueからList<CalculationState>?を安全に取り出す
    final currentHistory = ref.read(historyNotifierProvider).valueOrNull;

    // 履歴がnull(ローディング中/エラー)または空の場合のチェック
    if (currentHistory == null || currentHistory.isEmpty) {
      return 'エクスポートする履歴がありません。';
    }
    
    // `currentHistory`はList<CalculationState>として安全に渡せる
    final success = await _historyService.exportHistory(currentHistory);
    // ▲▲▲ 修正はここまで ▲▲▲
    
    return success ? '履歴を共有しました。' : 'エクスポートに失敗しました。';
  }

  /// CSVファイルから履歴データを読み込む
  Future<List<CalculationState>?> getImportedHistoryData() async {
    return await _historyService.importHistory();
  }

  /// 読み込んだ履歴データで現在の履歴を上書き保存する
  Future<void> saveImportedHistory(List<CalculationState> history) async {
    await ref.read(historyNotifierProvider.notifier).replaceAll(history);
  }
}