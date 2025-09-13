// lib/screens/history_page.dart

import 'package:flutter/material.dart';
import '../models/calculation_state.dart';
import '../services/settings_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/comment_edit_dialog.dart';

class HistoryPage extends StatefulWidget {
  final SettingsService settingsService;
  final List<CalculationState> history;
  final bool isJapaneseCalendar;

  const HistoryPage({
    super.key,
    required this.settingsService,
    required this.history,
    required this.isJapaneseCalendar,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<CalculationState> _history;

  @override
  void initState() {
    super.initState();
    // 画面の再描画に影響を与えないように、ウィジェットの履歴の新しいインスタンスを作成します。
    _history = List<CalculationState>.from(widget.history);
  }

  // --- ▼ 永続化を伴う並び替え処理 ▼ ---
  void _onReorder(int oldIndex, int newIndex) {
    //
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _history.removeAt(oldIndex);
    setState(() {
      _history.insert(newIndex, item);
    });
    // 永続化層に新しい順序を保存する
    widget.settingsService.saveHistory(_history);
  }

  Future<void> _clearHistory() async {
    await widget.settingsService.clearHistory();
    setState(() {
      _history.clear();
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
  
  Future<void> _editComment(int index) async {
    final originalState = _history[index];
    
    final newComment = await showCommentEditDialog(
      context,
      currentComment: originalState.comment,
    );

    if (newComment != null && newComment != originalState.comment) {
      final newState = originalState.copyWith(
        comment: newComment.isEmpty ? null : newComment,
      );
      
      setState(() {
        _history[index] = newState;
      });
      
      await widget.settingsService.saveHistory(_history);
    }
  }

  void _continueCalculation(int index) {
    final oldState = _history[index];
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('計算履歴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            onPressed: _history.isEmpty ? null : _showClearHistoryDialog,
          ),
        ],
      ),
      body: _history.isEmpty
          ? Center(
              child: Text(
                '計算履歴はありません。',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ReorderableListView.builder(
              itemCount: _history.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final state = _history[index];
                
                // --- ▼ Dismissibleウィジェットで各リスト項目をラップ ▼ ---
                return Dismissible(
                  // KeyはDismissibleとReorderableListViewの両方で必須です
                  key: ValueKey(state), 
                  direction: DismissDirection.endToStart,
                  //
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
                  // スワイプされた際の背景
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  // 削除が確定した後の処理
                  onDismissed: (direction) {
                    setState(() {
                      _history.removeAt(index);
                    });
                    widget.settingsService.saveHistory(_history);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「${state.comment ?? 'コメントなし'}」を削除しました')),
                    );
                  },
                  child: _buildHistoryTile(state, index),
                );
              },
            ),
    );
  }

  // --- ▼ ListTileの構築ロジックを別メソッドに分離 ▼ ---
  Widget _buildHistoryTile(CalculationState state, int index) {
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
            onPressed: () => _editComment(index),
          ),
          IconButton(
            icon: const Icon(Icons.double_arrow_outlined),
            tooltip: '続きから計算',
            onPressed: () => _continueCalculation(index),
          ),
        ],
      ),
    );
  }
}