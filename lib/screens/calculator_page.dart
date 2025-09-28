// lib/screens/calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/calculation_state.dart';
import '../providers/calculator_provider.dart';
import '../providers/history_management_provider.dart'; // 新しくインポート
import '../providers/services_provider.dart';
import '../services/calendar_service.dart';
import '../utils/constants.dart';
import '../widgets/calculator/action_buttons.dart';
import '../widgets/calculator/calculator_app_bar.dart';
import '../widgets/calculator/comment_display.dart';
import '../widgets/calculator/display_fields.dart';
import '../widgets/keypad.dart';
import 'history_page.dart';
import '../widgets/comment_edit_dialog.dart';
import '../helpers/show_app_snack_bar.dart';
import '../helpers/show_calendar_prompt.dart';

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

  void _onButtonPressed(String text) {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    switch (text) {
      case AppConstants.keyEnter:
        _handleEnter();
        break;
      case AppConstants.keyClear:
        notifier.onClearPressed();
        break;
      case AppConstants.keyBackspace:
        notifier.onBackspacePressed();
        break;
      case '+':
      case '-':
        notifier.onOperatorPressed(text);
        break;
      default:
        notifier.onNumberPressed(text);
        break;
    }
  }

  Future<void> _handleEnter() async {
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

    final String title =
        (state.comment?.isNotEmpty ?? false) ? state.comment! : '計算結果の日付';
    final DateTime startTime = state.finalDate!;

    final bool? add = await showCalendarPrompt(
      context,
      title: title,
      startTime: startTime,
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

    if (field == ActiveField.finalDate) {
      if (state.activeField == ActiveField.finalDate) {
        final picked = await showDatePicker(
          context: context,
          initialDate: state.finalDate ?? DateTime.now(),
          firstDate: AppConstants.minDate,
          lastDate: AppConstants.maxDate,
        );
        if (mounted && picked != null) {
          notifier.updateFinalDate(picked);
        }
      } else {
        notifier.settleCalculationAndFocusFinalDate();
      }
      return;
    }

    if (field == ActiveField.standardDate) {
      final picked = await showDatePicker(
        context: context,
        initialDate: state.standardDate,
        firstDate: AppConstants.minDate,
        lastDate: AppConstants.maxDate,
      );
      if (mounted && picked != null) {
        notifier.updateStandardDate(picked);
      }
    }
  }

  void _navigateToHistory() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final navigator = Navigator.of(context);

    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => HistoryPage(
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

    showAboutDialog(
        context: context,
        applicationName: 'くすりの日数計算機',
        applicationVersion: packageInfo.version,
        applicationLegalese: '© 2025 t-BocSoft');
  }

  /// エクスポート処理を新しいNotifierに委譲
  Future<void> _onExportHistory() async {
    final message = await ref
        .read(historyManagementNotifierProvider.notifier)
        .exportHistory();

    if (mounted) {
      showAppSnackBar(context, message);
    }
  }

  /// インポート処理を新しいNotifierに委譲
  Future<void> _onImportHistory() async {
    final notifier = ref.read(historyManagementNotifierProvider.notifier);
    final importedHistory = await notifier.getImportedHistoryData();

    if (!mounted) return;

    if (importedHistory == null) {
      showAppSnackBar(context, 'インポートがキャンセルされたか、ファイルの読み込みに失敗しました。');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴のインポート'),
        content: const Text('現在の履歴はすべて上書きされます。よろしいですか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('インポート')),
        ],
      ),
    );

    if (!mounted || !(confirmed ?? false)) return;

    await notifier.saveImportedHistory(importedHistory);

    if (mounted) {
      showAppSnackBar(context, '${importedHistory.length}件の履歴をインポートしました。');
    }
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
        onExportHistory: _onExportHistory,
        onImportHistory: _onImportHistory,
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
            CommentDisplay(
                comment: calculationState.comment, onEditComment: _editComment),
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
                areInputsDisabled:
                    calculationState.activeField == ActiveField.finalDate,
                settingsService: settingsService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}