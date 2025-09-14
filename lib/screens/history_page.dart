import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpodをインポート
import '../models/calculation_state.dart';
import '../models/history_filter_state.dart';
import '../providers/history_filter_provider.dart'; // 作成したProviderをインポート
import '../services/settings_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/comment_edit_dialog.dart';
import '../widgets/history/history_filter_dialog.dart';

// --- ▼▼▼ ConsumerStatefulWidget に変更 ▼▼▼ ---
class HistoryPage extends ConsumerStatefulWidget {
  final SettingsService settingsService;
  // historyは初期表示にのみ使用
  final List<CalculationState> history;
  final bool isJapaneseCalendar;

  const HistoryPage({
    super.key,
    required this.settingsService,
    required this.history,
    required this.isJapaneseCalendar,
  });

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  // --- ▲▲▲ ここまで ▲▲▲ ---

  // 全履歴を保持するリスト
  late List<CalculationState> _fullHistory;

  @override
  void initState() {
    super.initState();
    _fullHistory = List<CalculationState>.from(widget.history);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _fullHistory.removeAt(oldIndex);
    setState(() {
      _fullHistory.insert(newIndex, item);
    });
    widget.settingsService.saveHistory(_fullHistory);
  }

  Future<void> _clearHistory() async {
    await widget.settingsService.clearHistory();
    setState(() {
      _fullHistory.clear();
    });
  }
  
  void _showClearHistoryDialog() {
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
              _clearHistory();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showFilterDialog() async {
    final filterNotifier = ref.read(historyFilterNotifierProvider.notifier);
    final currentFilter = ref.read(historyFilterNotifierProvider);

    final newFilter = await showDialog<HistoryFilterState>(
      context: context,
      builder: (context) => HistoryFilterDialog(currentFilter: currentFilter),
    );

    if (newFilter != null) {
      filterNotifier.updateFilter(newFilter);
    }
  }

  Future<void> _editComment(int index, List<CalculationState> displayedHistory) async {
    final originalState = displayedHistory[index];
    
    final newComment = await showCommentEditDialog(
      context,
      currentComment: originalState.comment,
    );

    if (newComment != null && newComment != originalState.comment) {
      final newState = originalState.copyWith(
        comment: newComment.isEmpty ? null : newComment,
      );
      
      // 全履歴リストから該当の項目を探して更新
      final originalIndex = _fullHistory.indexWhere((item) => item == originalState);
      if (originalIndex != -1) {
        setState(() {
          _fullHistory[originalIndex] = newState;
        });
        await widget.settingsService.saveHistory(_fullHistory);
      }
    }
  }

  void _continueCalculation(int index, List<CalculationState> displayedHistory) {
    final oldState = displayedHistory[index];
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
  Widget build(BuildContext context) {
    // --- ▼▼▼ フィルターの状態を監視 ▼▼▼ ---
    final filter = ref.watch(historyFilterNotifierProvider);
    final filterNotifier = ref.read(historyFilterNotifierProvider.notifier);
    // --- ▲▲▲ ここまで ▲▲▲ ---

    // --- ▼▼▼ 絞り込みロジック ▼▼▼ ---
    final bool isFilterActive = filter.comment != null && filter.comment!.isNotEmpty ||
        filter.standardDateStart != null || filter.standardDateEnd != null ||
        filter.finalDateStart != null || filter.finalDateEnd != null;

    final List<CalculationState> displayedHistory = !isFilterActive
      ? _fullHistory
      : _fullHistory.where((item) {
          final conditions = <bool>[];
          
          // コメント
          if (filter.comment != null && filter.comment!.isNotEmpty) {
            conditions.add(item.comment?.toLowerCase().contains(filter.comment!.toLowerCase()) ?? false);
          }
          // 基準日
          if (filter.standardDateStart != null || filter.standardDateEnd != null) {
            bool isInRange = true;
            if (filter.standardDateStart != null && item.standardDate.isBefore(filter.standardDateStart!)) {
              isInRange = false;
            }
            if (filter.standardDateEnd != null && item.standardDate.isAfter(filter.standardDateEnd!.add(const Duration(days: 1)))) {
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
              if (filter.finalDateStart != null && item.finalDate!.isBefore(filter.finalDateStart!)) {
                isInRange = false;
              }
              if (filter.finalDateEnd != null && item.finalDate!.isAfter(filter.finalDateEnd!.add(const Duration(days: 1)))) {
                isInRange = false;
              }
              conditions.add(isInRange);
            }
          }

          if (conditions.isEmpty) return true;
          if (filter.logic == FilterLogic.and) return conditions.every((c) => c);
          return conditions.any((c) => c);

        }).toList();
    // --- ▲▲▲ ここまで ▲▲▲ ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('計算履歴'),
        actions: [
          IconButton(
            icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'フィルター',
            onPressed: _showFilterDialog,
          ),
          // --- ▼▼▼ フィルターリセットボタンを追加 ▼▼▼ ---
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'フィルターをリセット',
              onPressed: filterNotifier.resetFilter,
            ),
          // --- ▲▲▲ ここまで ▲▲▲ ---
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            onPressed: _fullHistory.isEmpty ? null : _showClearHistoryDialog,
          ),
        ],
      ),
      body: displayedHistory.isEmpty
          ? Center(
              child: Text(
                isFilterActive ? '条件に合う履歴はありません。' : '計算履歴はありません。',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          // --- ▼▼▼ フィルター適用中は並び替えを無効化 ▼▼▼ ---
          : ReorderableListView.builder(
              itemCount: displayedHistory.length,
              onReorder: isFilterActive ? (o, n) {} : _onReorder,
              itemBuilder: (context, index) {
                final state = displayedHistory[index];
                
                return Dismissible(
                  key: ValueKey(state), 
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
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
                  },
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _fullHistory.remove(state);
                    });
                    widget.settingsService.saveHistory(_fullHistory);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「${state.comment ?? 'コメントなし'}」を削除しました')),
                    );
                  },
                  child: _buildHistoryTile(state, index, displayedHistory, isFilterActive: isFilterActive),
                );
              },
            ),
    );
  }

  Widget _buildHistoryTile(CalculationState state, int index, List<CalculationState> displayedHistory, {required bool isFilterActive}) {
    final standardDateStr = formatDate(
      state.standardDate,
      isJapanese: widget.isJapaneseCalendar,
      style: DateFormatStyle.compact,
    );
    final finalDateStr = formatDate(
      state.finalDate,
      isJapanese: widget.isJapaneseCalendar,
      style: DateFormatStyle.compact,
    );
    final expressionStr = state.daysExpression
        .replaceAllMapped(RegExp(r'([+\-])'), (match) => ' ${match.group(1)} ');

    return ListTile(
      leading: isFilterActive ? null : const Icon(Icons.drag_handle),
      title: Text(
        state.comment ?? 'コメントなし',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '$standardDateStr $expressionStr\n= $finalDateStr',
      ),
      isThreeLine: true,
      onTap: () {
        Navigator.of(context).pop(state);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'コメントを編集',
            onPressed: () => _editComment(index, displayedHistory),
          ),
          IconButton(
            icon: const Icon(Icons.double_arrow_outlined),
            tooltip: '続きから計算',
            onPressed: () => _continueCalculation(index, displayedHistory),
          ),
        ],
      ),
    );
  }
}