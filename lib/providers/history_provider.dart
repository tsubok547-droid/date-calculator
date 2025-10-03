// lib/providers/history_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/calculation_state.dart';
import 'repositories_provider.dart';

part 'history_provider.g.dart';

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  Future<List<CalculationState>> build() {
    final repository = ref.watch(historyRepositoryProvider);
    return repository.getAll();
  }

  Future<void> add(CalculationState newState) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.add(newState);
    ref.invalidateSelf();
  }

  Future<void> remove(CalculationState itemToRemove) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;

    final repository = ref.read(historyRepositoryProvider);
    final newList = currentList.where((item) => item != itemToRemove).toList();
    await repository.updateAll(newList);

    state = AsyncData(newList);
  }

  Future<void> clear() async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.clearAll();
    state = const AsyncData([]);
  }

  Future<void> replaceAll(List<CalculationState> newHistory) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.updateAll(newHistory);
    state = AsyncData(newHistory);
  }

  // ▼▼▼ このメソッドを追加 ▼▼▼
  Future<int> merge(List<CalculationState> newItems) async {
    final repository = ref.read(historyRepositoryProvider);
    final count = await repository.mergeHistory(newItems);
    ref.invalidateSelf(); // 状態を更新してUIに反映
    return count;
  }
  // ▲▲▲ ここまで追加 ▲▲▲

  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;

    final repository = ref.read(historyRepositoryProvider);
    final list = List<CalculationState>.from(currentList);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await repository.updateAll(list);
    state = AsyncData(list);
  }

  Future<void> updateComment(
      CalculationState original, String newComment) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty) return;
        
    final repository = ref.read(historyRepositoryProvider);
    final newState =
        original.copyWith(comment: newComment.isEmpty ? null : newComment);
    final newList = currentList
        .map((item) => item.hashCode == original.hashCode ? newState : item)
        .toList();
    await repository.updateAll(newList);
    state = AsyncData(newList);
  }
}