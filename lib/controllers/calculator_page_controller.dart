import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../helpers/show_app_snack_bar.dart';
import '../helpers/show_calendar_prompt.dart';
import '../models/calculation_state.dart';
import '../providers/calculator_provider.dart';
import '../providers/history_management_provider.dart';
import '../providers/services_provider.dart';
import '../screens/history_page.dart';
import '../services/calendar_service.dart';
import '../utils/constants.dart';
import '../widgets/comment_edit_dialog.dart';

part 'calculator_page_controller.g.dart';

@riverpod
class CalculatorPageController extends _$CalculatorPageController {
  @override
  void build() {
    // このControllerは状態を持たず、メソッドの実行のみを責務とするため、
    // buildメソッドは空です。
  }

  /// キーパッドのボタンが押されたときの処理を振り分ける
  void onButtonPressed(String text) {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    switch (text) {
      case AppConstants.keyEnter:
        // Enterキーの処理は handleEnter() に委譲されているため、ここでは何もしない
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

  /// Enterキーが押されたときの複雑な処理
  ///
  /// @return ハイライトすべきフィールド（UI側でアニメーションを再生するために使用）
  Future<ActiveField?> handleEnter(BuildContext context) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);
    ActiveField? fieldToHighlight;

    // どのフィールドをハイライトするか決定
    if (state.activeField == ActiveField.daysExpression && state.finalDate != null) {
      fieldToHighlight = ActiveField.finalDate;
    } else if (state.activeField == ActiveField.finalDate) {
      fieldToHighlight = ActiveField.daysExpression;
    }

    if (state.finalDate == null) return null;

    // 履歴保存
    await notifier.saveCurrentStateToHistory();
    if (!context.mounted) return null;
    // カレンダー連携
    final settingsService = ref.read(settingsServiceProvider);
    if (settingsService.shouldAddEventToCalendar()) {
      await _promptAddEventToCalendar(context, state);
    }

    return fieldToHighlight;
  }

  /// コメントを編集するダイアログを表示
  Future<void> editComment(BuildContext context) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currentComment = ref.read(calculatorNotifierProvider).comment;

    final newComment = await showCommentEditDialog(
      context,
      currentComment: currentComment,
    );

    if (newComment == null) return;

    notifier.updateComment(newComment.isEmpty ? null : newComment);
  }

  /// 日付選択フィールドがタップされたときの処理
  Future<void> selectDate(BuildContext context, ActiveField field) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);

    if (field == ActiveField.daysExpression) {
      notifier.setActiveField(ActiveField.daysExpression);
      return;
    }

    DateTime? initialDate;
    if (field == ActiveField.finalDate) {
      if (state.activeField == ActiveField.finalDate) {
        initialDate = state.finalDate ?? DateTime.now();
      } else {
        notifier.settleCalculationAndFocusFinalDate();
        return;
      }
    } else if (field == ActiveField.standardDate) {
      initialDate = state.standardDate;
    }

    if (initialDate == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: AppConstants.minDate,
      lastDate: AppConstants.maxDate,
    );

    if (picked == null) return;

    if (field == ActiveField.finalDate) {
      notifier.updateFinalDate(picked);
    } else {
      notifier.updateStandardDate(picked);
    }
  }

  /// 履歴ページへ遷移
  Future<void> navigateToHistory(BuildContext context, {required bool isJapaneseCalendar}) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          isJapaneseCalendar: isJapaneseCalendar,
        ),
      ),
    );

    if (result is CalculationState) {
      notifier.restoreFromHistory(result);
    }
  }

  /// バージョン情報を表示
  Future<void> showVersionInfo(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
        context: context,
        applicationName: 'くすりの日数計算機',
        applicationVersion: packageInfo.version,
        applicationLegalese: '© 2025 t-BocSoft');
  }

  /// 履歴をエクスポート
  Future<void> exportHistory(BuildContext context) async {
    final message = await ref
        .read(historyManagementNotifierProvider.notifier)
        .exportHistory();
    if (context.mounted) {
      showAppSnackBar(context, message);
    }
  }

  /// 履歴をインポート
  Future<void> importHistory(BuildContext context) async {
    final notifier = ref.read(historyManagementNotifierProvider.notifier);
    final importedHistory = await notifier.getImportedHistoryData();

    if (!context.mounted) return;
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('インポート')),
        ],
      ),
    );

    if (!(confirmed ?? false)) return;

    await notifier.saveImportedHistory(importedHistory);

    if (context.mounted) {
      showAppSnackBar(context, '${importedHistory.length}件の履歴をインポートしました。');
    }
  }

  /// プライベートメソッド：カレンダーへの追加を確認
  Future<void> _promptAddEventToCalendar(BuildContext context, CalculationState state) async {
    final calendarService = CalendarService();
    if (state.finalDate == null) return;

    final String title = (state.comment?.isNotEmpty ?? false) ? state.comment! : '計算結果の日付';
    final DateTime startTime = state.finalDate!;

    final bool? add = await showCalendarPrompt(
      context,
      title: title,
      startTime: startTime,
    );

    if (!(add ?? false)) return;
    await calendarService.addEventToCalendar(state);
  }
}