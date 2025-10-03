import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../controllers/history_page_controller.dart';
import '../models/calculation_state.dart';
import '../providers/filtered_history_provider.dart';
import '../providers/history_filter_provider.dart';
import '../providers/history_provider.dart';
import '../utils/date_formatter.dart';

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

class HistoryPage extends ConsumerWidget {
  final bool isJapaneseCalendar;

  const HistoryPage({
    super.key,
    required this.isJapaneseCalendar,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(historyPageControllerProvider.notifier);
    final isFilterActive = ref.watch(isFilterActiveProvider);
    // ★ フィルタリング済みの履歴リストを監視する
    final asyncDisplayedHistory = ref.watch(filteredHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('計算履歴'),
        actions: [
          IconButton(
            icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'フィルター',
            onPressed: () => controller.showFilterDialog(context),
          ),
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'フィルターをリセット',
              onPressed: controller.resetFilter,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            // 元の履歴が空の場合にボタンを無効化
            onPressed: (ref.watch(historyNotifierProvider).valueOrNull?.isEmpty ?? true)
                ? null
                : () => controller.clearHistory(context),
          ),
        ],
      ),
      body: asyncDisplayedHistory.when(
        data: (displayedHistory) {
          // ★ フィルタリングロジックがなくなり、非常にシンプルに！
          if (displayedHistory.isEmpty) {
            return Center(
              child: Text(
                isFilterActive ? '条件に合う履歴はありません。' : '計算履歴はありません。',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          return ReorderableListView.builder(
            itemCount: displayedHistory.length,
            // フィルター適用時は並べ替えを無効化
            onReorder: isFilterActive 
              ? (oldIndex, newIndex) {} 
              : (oldIndex, newIndex) {
                  controller.reorderHistory(oldIndex, newIndex);
                },
            itemBuilder: (context, index) {
              final state = displayedHistory[index];
              return Dismissible(
                key: ValueKey(state.hashCode),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => controller.confirmRemove(context),
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                onDismissed: (direction) => controller.onRemoved(context, state),
                child: _buildHistoryTile(
                  context,
                  ref,
                  state,
                  isFilterActive: isFilterActive,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    WidgetRef ref,
    CalculationState state, {
    required bool isFilterActive,
  }) {
    final controller = ref.read(historyPageControllerProvider.notifier);
    final standardDateStr = formatDate(state.standardDate, isJapanese: isJapaneseCalendar, style: DateFormatStyle.compact);
    final finalDateStr = formatDate(state.finalDate, isJapanese: isJapaneseCalendar, style: DateFormatStyle.compact);
    final expressionStr = state.daysExpression.replaceAllMapped(RegExp(r'([+\-])'), (match) => ' ${match.group(1)} ');

    return ListTile(
      leading: isFilterActive ? null : const Icon(Icons.drag_handle),
      title: Text(state.comment ?? 'コメントなし', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$standardDateStr $expressionStr\n= $finalDateStr'),
      isThreeLine: true,
      onTap: () => Navigator.of(context).pop(state),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'コメントを編集',
            onPressed: () => controller.editComment(context, state),
          ),
          IconButton(
            icon: const Icon(Icons.double_arrow_outlined),
            tooltip: '続きから計算',
            onPressed: () => controller.continueCalculation(context, state),
          ),
        ],
      ),
    );
  }
}