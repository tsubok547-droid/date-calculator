import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../models/calculation_state.dart';
import '../providers/calculator_provider.dart';
import '../providers/services_provider.dart';
import '../services/calendar_service.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../widgets/calculator/action_buttons.dart';
import '../widgets/calculator/calculator_app_bar.dart';
import '../widgets/calculator/comment_display.dart';
import '../widgets/calculator/display_fields.dart';
import '../widgets/keypad.dart';
import 'history_page.dart';
import '../widgets/comment_edit_dialog.dart';

class CalculatorPage extends ConsumerStatefulWidget {
  final bool isJapaneseCalendar;
  final VoidCallback onCalendarModeChanged;

  const CalculatorPage({
    super.key,
    required this.isJapaneseCalendar,
    required this.onCalendarModeChanged,
  });

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  bool _isFinalDateHighlighted = false;
  bool _isDaysExpressionHighlighted = false;
  
  final _calendarService = CalendarService();
  final _historyService = HistoryService();

  void _onButtonPressed(String text) {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    switch (text) {
      case AppConstants.keyEnter: _handleEnter(); break;
      case AppConstants.keyClear: notifier.onClearPressed(); break;
      case AppConstants.keyBackspace: notifier.onBackspacePressed(); break;
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
      await notifier.saveCurrentStateToHistory();
      
      final settingsService = ref.read(settingsServiceProvider);
      if (settingsService.shouldAddEventToCalendar()) {
        await _promptAddEventToCalendar(state);
      }
    }
  }

  Future<void> _editComment() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currentComment = ref.read(calculatorNotifierProvider).comment;
    
    final newComment = await showCommentEditDialog(
      context,
      currentComment: currentComment,
    );
    
    if (!mounted || newComment == null) return;

    notifier.updateComment(newComment.isEmpty ? null : newComment);
  }

  Future<void> _promptAddEventToCalendar(CalculationState state) async {
    if (state.finalDate == null) return;
    
    final String title = (state.comment?.isNotEmpty ?? false) ? state.comment! : '計算結果の日付';
    final DateTime startTime = state.finalDate!;

    final bool? add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カレンダーに予定を追加'),
        content: Text('お使いのカレンダーアプリを開いて、以下の内容で予定を追加しますか？\n\nタイトル: $title\n日時: ${DateFormat('M月d日(E)', 'ja_JP').format(startTime)}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('追加')),
        ],
      ),
    );

    if (!mounted || !(add ?? false)) return;

    await _calendarService.addEventToCalendar(state);
  }

  Future<void> _selectDate(ActiveField field) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);

    if (field == ActiveField.daysExpression) {
      notifier.setActiveField(ActiveField.daysExpression);
      return;
    }
    
    final initialDate = (field == ActiveField.standardDate) ? state.standardDate : (state.finalDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: AppConstants.minDate,
      lastDate: AppConstants.maxDate,
    );
    
    if (!mounted || picked == null) return;

    if (field == ActiveField.standardDate) {
      notifier.updateStandardDate(picked);
    } else if (field == ActiveField.finalDate) {
      notifier.updateFinalDate(picked);
    }
  }

  void _navigateToHistory() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final settingsService = ref.read(settingsServiceProvider);
    
    final navigator = Navigator.of(context);

    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          settingsService: settingsService,
          history: settingsService.getHistory(),
          isJapaneseCalendar: widget.isJapaneseCalendar,
        ),
      ),
    );

    if (!mounted) return;

    if (result is CalculationState) {
      notifier.restoreFromHistory(result);
    }
  }

  void _showVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!mounted) return;
    
    showAboutDialog(context: context, applicationName: 'くすりの日数計算機', applicationVersion: packageInfo.version, applicationLegalese: '© 2025 t-BocSoft');
  }

  Future<void> _exportHistory() async {
    final settingsService = ref.read(settingsServiceProvider);
    final currentHistory = settingsService.getHistory();

    if (currentHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エクスポートする履歴がありません。')),
      );
      return;
    }

    final success = await _historyService.exportHistory(currentHistory);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('履歴を共有しました。')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エクスポートに失敗しました。')),
      );
    }
  }
  
  Future<void> _importHistory() async {
    final List<CalculationState>? importedHistory = await _historyService.importHistory();
    
    if (!mounted) return;

    if (importedHistory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('インポートがキャンセルされたか、ファイルの読み込みに失敗しました。')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴のインポート'),
        content: const Text('現在の履歴はすべて上書きされます。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('インポート')),
        ],
      ),
    );
    
    if (!mounted || !(confirmed ?? false)) return;

    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.saveHistory(importedHistory);
    ref.invalidate(settingsServiceProvider);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${importedHistory.length}件の履歴をインポートしました。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculationState = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final settingsService = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: CalculatorAppBar(
        onNavigateToHistory: _navigateToHistory,
        onShowVersionInfo: _showVersionInfo,
        onExportHistory: _exportHistory,
        onImportHistory: _importHistory,
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
                areInputsDisabled: calculationState.activeField == ActiveField.finalDate,
                settingsService: settingsService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}