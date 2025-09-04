// lib/screens/history_page.dart

import 'package:flutter/material.dart';
import '../models/calculation_state.dart';
import '../services/settings_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/comment_edit_dialog.dart'; // --- ▼ この行を追加 ▼ ---

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
    _history = widget.history;
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

  // --- ▼ _editCommentメソッドを修正 ▼ ---
  Future<void> _editComment(int index) async {
    final originalState = _history[index];
    
    // 共通ダイアログを呼び出す
    final newComment = await showCommentEditDialog(
      context,
      currentComment: originalState.comment,
    );

    // ダイアログがキャンセルされず、内容が変更された場合のみ更新
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
  // --- ▲ ここまで ▲ ---

  // --- ▼ 不要になったのでこのメソッドを削除 ▼ ---
  // Future<String?> _showEditCommentDialog(String? currentComment) { ... }
  // --- ▲ ここまで ▲ ---

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
          : ListView.separated(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final state = _history[index];
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
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
    );
  }
}