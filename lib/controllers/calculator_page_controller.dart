// lib/controllers/calculator_page_controller.dart

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

// インポート方法を定義するenum
enum ImportAction { merge, replace }

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
  Future<ActiveField?> handleEnter(BuildContext context) async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final state = ref.read(calculatorNotifierProvider);
    ActiveField? fieldToHighlight;

    if (state.activeField == ActiveField.daysExpression &&
        state.finalDate != null) {
      fieldToHighlight = ActiveField.finalDate;
    } else if (state.activeField == ActiveField.finalDate) {
      fieldToHighlight = ActiveField.daysExpression;
    }

    if (state.finalDate == null) return null;

    await notifier.saveCurrentStateToHistory();
    if (!context.mounted) return null;

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
  Future<void> navigateToHistory(BuildContext context,
      {required bool isJapaneseCalendar}) async {
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
    final mgmtNotifier = ref.read(historyManagementNotifierProvider.notifier);
    final importedHistory = await mgmtNotifier.getImportedHistoryData();

    if (!context.mounted) return;

    if (importedHistory == null) {
      showAppSnackBar(
          context, 'インポートがキャンセルされたか、ファイルの読み込みに失敗しました。');
      return;
    }

    final ImportAction? action = await showDialog<ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴のインポート'),
        content: const Text(
          'インポート方法を選択してください。\n\n'
          '・マージ: 既存の履歴に新しいデータを追加します。\n'
          '・上書き: 既存の履歴をすべて削除し、新しいデータに置き換えます。',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(ImportAction.merge),
              child: const Text('マージ')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(ImportAction.replace),
            child: const Text('上書き'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (action == null) {
      showAppSnackBar(context, 'インポートをキャンセルしました。');
      return;
    }

    final message =
        await mgmtNotifier.saveImportedHistory(importedHistory, action);

    if (context.mounted) {
      showAppSnackBar(context, message);
    }
  }

  /// プライベートメソッド：カレンダーへの追加を確認
  Future<void> _promptAddEventToCalendar(
      BuildContext context, CalculationState state) async {
    final calendarService = CalendarService();
    if (state.finalDate == null) return;

    final String title =
        (state.comment?.isNotEmpty ?? false) ? state.comment! : '計算結果の日付';
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