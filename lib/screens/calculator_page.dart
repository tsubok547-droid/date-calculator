import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/calculator_page_controller.dart';
import '../models/calculation_state.dart';
import '../providers/calculator_provider.dart';
import '../providers/services_provider.dart';
import '../utils/constants.dart';
import '../widgets/calculator/action_buttons.dart';
import '../widgets/calculator/calculator_app_bar.dart';
import '../widgets/calculator/comment_display.dart';
import '../widgets/calculator/display_fields.dart';
import '../widgets/keypad.dart';

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
  // UIの状態（ハイライトアニメーション）のみを管理
  bool _isFinalDateHighlighted = false;
  bool _isDaysExpressionHighlighted = false;

  /// キーパッドからの入力をControllerに渡す
  void _onButtonPressed(String text) {
    if (text == AppConstants.keyEnter) {
      _handleEnter();
    } else {
      ref.read(calculatorPageControllerProvider.notifier).onButtonPressed(text);
    }
  }

  /// Enterキーの処理。ロジックはControllerに委譲し、UIアニメーションのみ実行
  Future<void> _handleEnter() async {
    final fieldToHighlight = await ref.read(calculatorPageControllerProvider.notifier).handleEnter(context);

    if (!mounted || fieldToHighlight == null) return;

    if (fieldToHighlight == ActiveField.finalDate) {
      setState(() => _isFinalDateHighlighted = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isFinalDateHighlighted = false);
      });
    } else if (fieldToHighlight == ActiveField.daysExpression) {
      setState(() => _isDaysExpressionHighlighted = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isDaysExpressionHighlighted = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculationState = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final settingsService = ref.watch(settingsServiceProvider);
    
    // Controllerへの参照
    final controller = ref.read(calculatorPageControllerProvider.notifier);

    return Scaffold(
      appBar: CalculatorAppBar(
        onNavigateToHistory: () => controller.navigateToHistory(context, isJapaneseCalendar: widget.isJapaneseCalendar),
        onShowVersionInfo: () => controller.showVersionInfo(context),
        onExportHistory: () => controller.exportHistory(context),
        onImportHistory: () => controller.importHistory(context),
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
              comment: calculationState.comment,
              onEditComment: () => controller.editComment(context),
            ),
            DisplayFields(
              calculationState: calculationState,
              isJapaneseCalendar: widget.isJapaneseCalendar,
              isDaysExpressionHighlighted: _isDaysExpressionHighlighted,
              isFinalDateHighlighted: _isFinalDateHighlighted,
              onSelectDate: (field) => controller.selectDate(context, field),
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