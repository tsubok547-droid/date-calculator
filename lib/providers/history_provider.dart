// lib/providers/history_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/calculation_state.dart';
import 'repositories_provider.dart';

part 'history_provider.g.dart';

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  // buildメソッドは非同期にリポジトリを読み込み、Future<List>を返す
  @override
  Future<List<CalculationState>> build() async {
    final repository = await ref.watch(historyRepositoryProvider.future);
    return repository.getAll();
  }

  /// 新しい履歴を追加する
  Future<void> add(CalculationState newState) async {
    final repository = await ref.read(historyRepositoryProvider.future);
    await repository.add(newState);
    ref.invalidateSelf(); // invalidateSelfで再ビルドをトリガー
  }

  /// 履歴を1件削除する
  Future<void> remove(CalculationState itemToRemove) async {
    // state.valueで現在のデータを安全に取得
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;

    final repository = await ref.read(historyRepositoryProvider.future);
    final newList = currentList.where((item) => item != itemToRemove).toList();
    await repository.updateAll(newList);

    // 新しいデータで状態を更新
    state = AsyncData(newList);
  }

  /// 全履歴をクリアする
  Future<void> clear() async {
    final repository = await ref.read(historyRepositoryProvider.future);
    await repository.clearAll();
    state = const AsyncData([]); // 空のデータで状態を更新
  }

  /// インポートされた履歴で全件を置き換える
  Future<void> replaceAll(List<CalculationState> newHistory) async {
    final repository = await ref.read(historyRepositoryProvider.future);
    await repository.updateAll(newHistory);
    state = AsyncData(newHistory); // 新しいデータで状態を更新
  }

  /// 履歴を並べ替える
  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;

    final repository = await ref.read(historyRepositoryProvider.future);
    final list = List<CalculationState>.from(currentList);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await repository.updateAll(list);
    state = AsyncData(list); // 新しいデータで状態を更新
  }

  /// コメントを更新する
  Future<void> updateComment(
      CalculationState original, String newComment) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;
        
    final repository = await ref.read(historyRepositoryProvider.future);
    final newState =
        original.copyWith(comment: newComment.isEmpty ? null : newComment);
    final newList = currentList
        .map((item) => item.hashCode == original.hashCode ? newState : item)
        .toList();
    await repository.updateAll(newList);
    state = AsyncData(newList); // 新しいデータで状態を更新
  }
}