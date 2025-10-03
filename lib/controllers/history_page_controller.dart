import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../helpers/show_app_snack_bar.dart';
import '../models/calculation_state.dart';
import '../models/history_filter_state.dart';
import '../providers/history_filter_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/comment_edit_dialog.dart';
import '../widgets/history/history_filter_dialog.dart';

part 'history_page_controller.g.dart';

@riverpod
class HistoryPageController extends _$HistoryPageController {
  @override
  void build() {}

  /// フィルターダイアログを表示
  Future<void> showFilterDialog(BuildContext context) async {
    final newFilter = await showDialog<HistoryFilterState>(
      context: context,
      builder: (context) => HistoryFilterDialog(
        currentFilter: ref.read(historyFilterNotifierProvider),
      ),
    );
    if (newFilter != null) {
      ref.read(historyFilterNotifierProvider.notifier).updateFilter(newFilter);
    }
  }

  /// フィルターをリセット
  void resetFilter() {
    ref.read(historyFilterNotifierProvider.notifier).resetFilter();
  }

  /// 全履歴を削除する確認ダイアログを表示
  Future<void> clearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴をクリア'),
        content: const Text('すべての計算履歴を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(historyNotifierProvider.notifier).clear();
    }
  }

  /// 履歴を削除する前の確認ダイアログ（Dismissible用）
  Future<bool?> confirmRemove(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴の削除'),
        content: const Text('この履歴を削除してもよろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除')),
        ],
      ),
    );
  }

  /// 履歴が削除された後に呼び出される処理（Dismissible用）
  void onRemoved(BuildContext context, CalculationState item) {
    ref.read(historyNotifierProvider.notifier).remove(item);
    showAppSnackBar(context, '「${item.comment ?? 'コメントなし'}」を削除しました');
  }

  /// 履歴を並べ替える
  Future<void> reorderHistory(int oldIndex, int newIndex) async {
    // 注: このインデックスはフィルタリングされていない元のリストに基づいている必要があります。
    // UI側でフィルター適用時は並べ替えを無効化することで整合性を保ちます。
    await ref.read(historyNotifierProvider.notifier).reorder(oldIndex, newIndex);
  }

  /// コメントを編集する
  Future<void> editComment(BuildContext context, CalculationState original) async {
    final newComment = await showCommentEditDialog(
      context,
      currentComment: original.comment,
    );
    if (newComment != null && newComment != original.comment) {
      await ref.read(historyNotifierProvider.notifier).updateComment(original, newComment);
    }
  }
  
  /// 続きから計算する
  void continueCalculation(BuildContext context, CalculationState oldState) {
    if (oldState.finalDate == null) return;
    final newState = CalculationState(
      standardDate: oldState.finalDate!,
      daysExpression: '0',
      finalDate: oldState.finalDate,
      comment: oldState.comment,
      activeField: ActiveField.daysExpression,
    );
    Navigator.of(context).pop(newState);
  }
}