import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/history_filter_state.dart';
import '../../utils/constants.dart'; // 定数ファイルをインポート

class HistoryFilterDialog extends StatefulWidget {
  final HistoryFilterState currentFilter;

  const HistoryFilterDialog({super.key, required this.currentFilter});

  @override
  State<HistoryFilterDialog> createState() => _HistoryFilterDialogState();
}

class _HistoryFilterDialogState extends State<HistoryFilterDialog> {
  late TextEditingController _commentController;
  late HistoryFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _commentController = TextEditingController(text: _filter.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart, required bool isStandard}) async {
    final initialDate = (isStart 
      ? (isStandard ? _filter.standardDateStart : _filter.finalDateStart) 
      : (isStandard ? _filter.standardDateEnd : _filter.finalDateEnd)) ?? DateTime.now();
      
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: AppConstants.minDate, // 定数を使用
      lastDate: AppConstants.maxDate,  // 定数を使用
    );

    if (picked != null) {
      setState(() {
        if (isStandard) {
          if (isStart) {
            _filter = _filter.copyWith(standardDateStart: picked);
          } else {
            _filter = _filter.copyWith(standardDateEnd: picked);
          }
        } else {
          if (isStart) {
            _filter = _filter.copyWith(finalDateStart: picked);
          } else {
            _filter = _filter.copyWith(finalDateEnd: picked);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('履歴をフィルター'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // コメントフィルター
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'コメント（部分一致）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment_outlined),
              ),
              onChanged: (value) {
                // ダイアログを閉じる時に適用するので、ここでは何もしない
              },
            ),
            const Divider(height: 32),
            // 基準日フィルター
            _buildDateRangePicker(
              context: context,
              title: '基準日の期間',
              startDate: _filter.standardDateStart,
              endDate: _filter.standardDateEnd,
              onSelectStart: () => _selectDate(context, isStart: true, isStandard: true),
              onSelectEnd: () => _selectDate(context, isStart: false, isStandard: true),
            ),
            const SizedBox(height: 16),
            // 最終日フィルター
            _buildDateRangePicker(
              context: context,
              title: '最終日の期間',
              startDate: _filter.finalDateStart,
              endDate: _filter.finalDateEnd,
              onSelectStart: () => _selectDate(context, isStart: true, isStandard: false),
              onSelectEnd: () => _selectDate(context, isStart: false, isStandard: false),
            ),
            
            // --- ▼▼▼ AND/ORスイッチを追加 ▼▼▼ ---
            const Divider(height: 32),
            Text('絞り込み条件', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<FilterLogic>(
              segments: const [
                ButtonSegment(value: FilterLogic.and, label: Text('AND')),
                ButtonSegment(value: FilterLogic.or, label: Text('OR')),
              ],
              selected: {_filter.logic},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _filter = _filter.copyWith(logic: newSelection.first);
                });
              },
            ),
            // --- ▲▲▲ ここまで ▲▲▲ ---
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // 変更を破棄
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            // 適用時にテキストフィールドの最新の値を反映
            final finalFilter = _filter.copyWith(comment: _commentController.text);
            Navigator.of(context).pop(finalFilter);
          },
          child: const Text('適用'),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker({
    required BuildContext context,
    required String title,
    DateTime? startDate,
    DateTime? endDate,
    required VoidCallback onSelectStart,
    required VoidCallback onSelectEnd,
  }) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onSelectStart,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Text(startDate != null ? dateFormat.format(startDate) : '開始日'),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('～'),
            ),
            Expanded(
              child: InkWell(
                onTap: onSelectEnd,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Text(endDate != null ? dateFormat.format(endDate) : '終了日'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}