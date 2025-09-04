// lib/screens/calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calculation_state.dart';
import '../providers/calculator_provider.dart';
import '../providers/services_provider.dart';
import '../widgets/calculator/action_buttons.dart';
import '../widgets/calculator/calculator_app_bar.dart';
import '../widgets/calculator/comment_display.dart';
import '../widgets/calculator/display_fields.dart';
import '../widgets/keypad.dart';
import 'history_page.dart';
import '../widgets/comment_edit_dialog.dart'; 

class CalculatorPage extends ConsumerStatefulWidget {
  final Function(Color) onColorChanged;
  final bool isJapaneseCalendar;
  final VoidCallback onCalendarModeChanged;

  const CalculatorPage({
    super.key,
    required this.onColorChanged,
    required this.isJapaneseCalendar,
    required this.onCalendarModeChanged,
  });

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  // ハイライトアニメーション用の状態
  bool _isFinalDateHighlighted = false;
  bool _isDaysExpressionHighlighted = false;

  final Map<String, Color> _predefinedColors = {
    'インディゴ': Colors.indigo,
    'アッシュグレー': const Color(0xFF78909C),
    'ダスティミント': const Color(0xFF80CBC4),
    'スカイブルー': const Color(0xFF64B5F6),
    'ラベンダー': const Color(0xFFB39DDB),
    'アイボリー': const Color(0xFFFFF9C4),
    'ダスティローズ': const Color(0xFFE57373),
  };
  
  // --- Event Handlers & UI Logic ---
  void _onButtonPressed(String text) {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    switch (text) {
      case 'Ent': _handleEnter(); break;
      case 'C': notifier.onClearPressed(); break;
      case '←': notifier.onBackspacePressed(); break;
      case '+':
      case '-': notifier.onOperatorPressed(text); break;
      default: notifier.onNumberPressed(text); break;
    }
  }

  void _handleEnter() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);

    if (state.activeField == ActiveField.daysExpression) {
      if (state.finalDate != null) {
        setState(() => _isFinalDateHighlighted = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isFinalDateHighlighted = false);
        });
      }
    } else if (state.activeField == ActiveField.finalDate) {
      setState(() => _isDaysExpressionHighlighted = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isDaysExpressionHighlighted = false);
      });
    }

    if (state.finalDate != null) {
      await notifier.saveHistory();
      if (mounted) await _promptAddEventToCalendar(state);
    }
  }

  Future<void> _editComment() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currentComment = ref.read(calculatorNotifierProvider).comment;

    // 共通ダイアログを呼び出す
    final newComment = await showCommentEditDialog(
      context,
      currentComment: currentComment,
    );

    // ダイアログがキャンセルされなかった場合のみ更新
    if (newComment != null) {
      notifier.updateComment(newComment.isEmpty ? null : newComment);
    }
  }

  Future<void> _promptAddEventToCalendar(CalculationState state) async {
    if (state.finalDate == null) return;
    final String title = (state.comment?.isNotEmpty ?? false) ? '${state.comment} 最終日' : '最終日';
    final DateTime startTime = DateTime(state.finalDate!.year, state.finalDate!.month, state.finalDate!.day, 9, 0);
    final DateTime endTime = startTime.add(const Duration(hours: 1));

    final bool? add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カレンダーに予定を追加'),
        content: Text('以下の内容で予定を追加しますか？\n\nタイトル: $title\n日時: ${DateFormat('M月d日(E) 9:00', 'ja_JP').format(startTime)}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('追加')),
        ],
      ),
    );

    if (add ?? false) {
      await Add2Calendar.addEvent2Cal(Event(title: title, startDate: startTime, endDate: endTime));
    }
  }

  Future<void> _selectDate(ActiveField field) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);

    if (field == ActiveField.daysExpression) {
      notifier.setActiveField(ActiveField.daysExpression);
      return;
    }
    
    final initialDate = (field == ActiveField.standardDate) ? state.standardDate : (state.finalDate ?? DateTime.now());
    final picked = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1926), lastDate: DateTime(2101));
    if (picked == null) return;

    if (field == ActiveField.standardDate) {
      notifier.updateStandardDate(picked);
    } else if (field == ActiveField.finalDate) {
      notifier.updateFinalDate(picked);
    }
  }

  void _navigateToHistory() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final settingsService = ref.read(settingsServiceProvider);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          settingsService: settingsService,
          history: settingsService.getHistory(),
          isJapaneseCalendar: widget.isJapaneseCalendar,
        ),
      ),
    );

    if (result is CalculationState) {
      notifier.restoreFromHistory(result);
    }
  }
  
  void _showColorPicker() {
    Color pickerColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カスタムカラーを選択'),
          content: SingleChildScrollView(child: ColorPicker(pickerColor: pickerColor, onColorChanged: (color) => pickerColor = color)),
          actions: [
            TextButton(
              child: const Text('決定'),
              onPressed: () {
                widget.onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showAboutDialog(context: context, applicationName: '日付計算ツール', applicationVersion: packageInfo.version, applicationLegalese: '© 2025 t-BocSoft');
  }

  @override
  Widget build(BuildContext context) {
    // Providerから状態を監視
    final calculationState = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);

    return Scaffold(
      appBar: CalculatorAppBar(
        onNavigateToHistory: _navigateToHistory,
        onColorChanged: widget.onColorChanged,
        onShowColorPicker: _showColorPicker,
        onShowVersionInfo: _showVersionInfo,
        predefinedColors: _predefinedColors,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            ActionButtons(
              onResetToToday: notifier.resetToToday,
              onCalendarModeChanged: widget.onCalendarModeChanged,
              isJapaneseCalendar: widget.isJapaneseCalendar,
            ),
            const SizedBox(height: 8),
            CommentDisplay(comment: calculationState.comment, onEditComment: _editComment),
            DisplayFields(
              calculationState: calculationState,
              isJapaneseCalendar: widget.isJapaneseCalendar,
              isDaysExpressionHighlighted: _isDaysExpressionHighlighted,
              isFinalDateHighlighted: _isFinalDateHighlighted,
              onSelectDate: _selectDate,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Keypad(
                onButtonPressed: _onButtonPressed,
                onShortcutPressed: notifier.onShortcutPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}