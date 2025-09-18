import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/calculation_state.dart';
import '../models/history_filter_state.dart';
import '../providers/history_filter_provider.dart';
import '../providers/history_provider.dart';
import '../utils/date_formatter.dart';
import '../widgets/comment_edit_dialog.dart';
import '../widgets/history/history_filter_dialog.dart';
import '../helpers/show_app_snack_bar.dart';

part 'history_page.g.dart';

/// フィルターがアクティブかどうかを判定するProvider
@riverpod
bool isFilterActive(Ref ref) {
  final filter = ref.watch(historyFilterNotifierProvider);
  return filter.comment != null && filter.comment!.isNotEmpty ||
      filter.standardDateStart != null ||
      filter.standardDateEnd != null ||
      filter.finalDateStart != null ||
      filter.finalDateEnd != null;
}

/// フィルターされた履歴リストを提供するProvider
@riverpod
List<CalculationState> filteredHistory(Ref ref) {
  // 元となる全履歴リストを監視
  final fullHistory = ref.watch(historyNotifierProvider);
  // フィルター条件を監視
  final filter = ref.watch(historyFilterNotifierProvider);
  // フィルターがアクティブでなければ全履歴をそのまま返す
  if (!ref.watch(isFilterActiveProvider)) {
    return fullHistory;
  }

  return fullHistory.where((item) {
    final conditions = <bool>[];

    // コメント
    if (filter.comment != null && filter.comment!.isNotEmpty) {
      conditions
          .add(item.comment?.toLowerCase().contains(filter.comment!.toLowerCase()) ?? false);
    }
    // 基準日
    if (filter.standardDateStart != null || filter.standardDateEnd != null) {
      bool isInRange = true;
      if (filter.standardDateStart != null &&
          item.standardDate.isBefore(filter.standardDateStart!)) {
        isInRange = false;
      }
      if (filter.standardDateEnd != null &&
          item.standardDate.isAfter(filter.standardDateEnd!.add(const Duration(days: 1)))) {
        isInRange = false;
      }
      conditions.add(isInRange);
    }
    // 最終日
    if (filter.finalDateStart != null || filter.finalDateEnd != null) {
      if (item.finalDate == null) {
        conditions.add(false);
      } else {
        bool isInRange = true;
        if (filter.finalDateStart != null &&
            item.finalDate!.isBefore(filter.finalDateStart!)) {
          isInRange = false;
        }
        if (filter.finalDateEnd != null &&
            item.finalDate!.isAfter(filter.finalDateEnd!.add(const Duration(days: 1)))) {
          isInRange = false;
        }
        conditions.add(isInRange);
      }
    }

    if (conditions.isEmpty) return true;
    if (filter.logic == FilterLogic.and) return conditions.every((c) => c);
    return conditions.any((c) => c);
  }).toList();
}

class HistoryPage extends ConsumerWidget {
  final bool isJapaneseCalendar;

  const HistoryPage({
    super.key,
    required this.isJapaneseCalendar,
  });

  Future<void> _showFilterDialog(BuildContext context, WidgetRef ref) async {
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

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴をクリア'),
        content: const Text('すべての計算履歴を削除しますか？'),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('削除'),
            onPressed: () {
              ref.read(historyNotifierProvider.notifier).clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _continueCalculation(BuildContext context, CalculationState oldState) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFilterActive = ref.watch(isFilterActiveProvider);
    final fullHistory = ref.watch(historyNotifierProvider);
    final displayedHistory = ref.watch(filteredHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('計算履歴'),
        actions: [
          IconButton(
            icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'フィルター',
            onPressed: () => _showFilterDialog(context, ref),
          ),
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'フィルターをリセット',
              onPressed: ref.read(historyFilterNotifierProvider.notifier).resetFilter,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            onPressed: fullHistory.isEmpty
                ? null
                : () => _showClearHistoryDialog(context, ref),
          ),
        ],
      ),
      body: () {
        if (isFilterActive && displayedHistory.isEmpty) {
          return Center(
            child: Text('条件に合う履歴はありません。', style: Theme.of(context).textTheme.titleMedium),
          );
        }
        if (fullHistory.isEmpty) {
          return Center(
            child: Text('計算履歴はありません。', style: Theme.of(context).textTheme.titleMedium),
          );
        }
        return ReorderableListView.builder(
          itemCount: displayedHistory.length,
          onReorder: isFilterActive
              ? (o, n) {}
              : (oldIndex, newIndex) =>
                  ref.read(historyNotifierProvider.notifier).reorder(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final state = displayedHistory[index];
            return Dismissible(
              key: ValueKey(state.hashCode),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDismiss(context),
              background: Container(
                color: Colors.red.shade400,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              onDismissed: (direction) {
                ref.read(historyNotifierProvider.notifier).remove(state);
                showAppSnackBar(context, '「${state.comment ?? 'コメントなし'}」を削除しました');
              },
              child: _buildHistoryTile(
                context,
                ref,
                state,
                isFilterActive: isFilterActive,
              ),
            );
          },
        );
      }(),
    );
  }

  Future<bool?> _confirmDismiss(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴の削除'),
        content: const Text('この履歴を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    WidgetRef ref,
    CalculationState state, {
    required bool isFilterActive,
  }) {
    final standardDateStr = formatDate(
      state.standardDate,
      isJapanese: isJapaneseCalendar,
      style: DateFormatStyle.compact,
    );
    final finalDateStr = formatDate(
      state.finalDate,
      isJapanese: isJapaneseCalendar,
      style: DateFormatStyle.compact,
    );
    final expressionStr =
        state.daysExpression.replaceAllMapped(RegExp(r'([+\-])'), (match) => ' ${match.group(1)} ');

    return ListTile(
      leading: isFilterActive ? null : const Icon(Icons.drag_handle),
      title: Text(
        state.comment ?? 'コメントなし',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$standardDateStr $expressionStr\n= $finalDateStr'),
      isThreeLine: true,
      onTap: () => Navigator.of(context).pop(state),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'コメントを編集',
            onPressed: () async {
              final newComment = await showCommentEditDialog(
                context,
                currentComment: state.comment,
              );
              if (newComment != null && newComment != state.comment) {
                ref.read(historyNotifierProvider.notifier).updateComment(state, newComment);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.double_arrow_outlined),
            tooltip: '続きから計算',
            onPressed: () => _continueCalculation(context, state),
          ),
        ],
      ),
    );
  }
}