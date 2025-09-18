// lib/providers/history_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/calculation_state.dart';
import 'repositories_provider.dart';
import 'services_provider.dart';

part 'history_provider.g.dart';

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  // RepositoryとServiceの両方を参照する
  late final _repository = ref.read(historyRepositoryProvider);
  late final _settingsService = ref.read(settingsServiceProvider);

  @override
  List<CalculationState> build() {
    // 履歴の読み込みはSettingsServiceから行う
    return _settingsService.getHistory();
  }

  /// 新しい履歴を追加する（重複ロジックが適用される）
  Future<void> add(CalculationState newState) async {
    // 1件追加のロジックはRepositoryのsaveメソッドを呼び出す
    await _repository.save(newState);
    // 状態を再生成してUIを更新する
    ref.invalidateSelf();
  }

  /// 履歴を1件削除する
  Future<void> remove(CalculationState itemToRemove) async {
    final currentList = state;
    final newList = currentList.where((item) => item != itemToRemove).toList();
    // リスト全体の保存はSettingsServiceを直接呼び出す
    await _settingsService.saveHistory(newList);
    state = newList; // UIの状態を更新
  }

  /// 全履歴をクリアする
  Future<void> clear() async {
    // クリアもSettingsServiceを呼び出す
    await _settingsService.clearHistory();
    state = []; // UIの状態を更新
  }

  /// 履歴を並べ替える
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<CalculationState>.from(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    // 並べ替え後のリスト全体を保存するのもSettingsService
    await _settingsService.saveHistory(list);
    state = list; // UIの状態を更新
  }

  /// コメントを更新する
  Future<void> updateComment(CalculationState original, String newComment) async {
    final newState = original.copyWith(comment: newComment.isEmpty ? null : newComment);
    final newList = state.map((item) => item.hashCode == original.hashCode ? newState : item).toList();
    // 更新後のリスト全体を保存するのもSettingsService
    await _settingsService.saveHistory(newList);
    state = newList; // UIの状態を更新
  }
}