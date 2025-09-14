import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:math_expressions/math_expressions.dart';
import '../models/calculation_state.dart';
import '../services/settings_service.dart'; // SettingsServiceをインポート
import '../models/history_duplicate_policy.dart'; // enumをインポート
import 'services_provider.dart';

part 'calculator_provider.g.dart';

@riverpod
class CalculatorNotifier extends _$CalculatorNotifier {
  @override
  CalculationState build() {
    final initialState = CalculationState(
      standardDate: DateTime.now(),
      daysExpression: '0',
    );
    return _calculateFinalDate(initialState);
  }

  void onNumberPressed(String number) {
    if (state.activeField != ActiveField.daysExpression) return;
    
    final newExpression = (state.daysExpression == '0')
        ? number
        : state.daysExpression + number;
    
    state = _calculateFinalDate(state.copyWith(daysExpression: newExpression));
  }

  void onOperatorPressed(String operator) {
    if (state.activeField != ActiveField.daysExpression) return;

    final lastChar = state.daysExpression.substring(state.daysExpression.length - 1);
    String newExpression;
    if ("+-".contains(lastChar)) {
      newExpression = state.daysExpression.substring(0, state.daysExpression.length - 1) + operator;
    } else {
      newExpression = state.daysExpression + operator;
    }
    state = _calculateFinalDate(state.copyWith(daysExpression: newExpression));
  }

  void onBackspacePressed() {
    if (state.activeField != ActiveField.daysExpression) return;
    
    final newExpression = (state.daysExpression.length > 1)
        ? state.daysExpression.substring(0, state.daysExpression.length - 1)
        : '0';

    state = _calculateFinalDate(state.copyWith(daysExpression: newExpression));
  }

  void onClearPressed() {
    state = _calculateFinalDate(state.copyWith(
      daysExpression: '0',
      comment: '',
      activeField: ActiveField.daysExpression,
    ));
  }

  void onShortcutPressed(int days) {
    final newExpression = (state.daysExpression == '0')
      ? days.toString()
      : "${state.daysExpression}+$days";

    state = _calculateFinalDate(state.copyWith(
      daysExpression: newExpression,
      activeField: ActiveField.daysExpression,
    ));
  }
  
  void resetToToday() {
    state = _recalculate(state.copyWith(standardDate: DateTime.now()));
  }

  void setActiveField(ActiveField field) {
    state = state.copyWith(activeField: field);
  }

  void updateStandardDate(DateTime date) {
    state = _recalculate(state.copyWith(standardDate: date, activeField: ActiveField.standardDate));
  }

  void updateFinalDate(DateTime date) {
    state = _recalculate(state.copyWith(finalDate: date, activeField: ActiveField.finalDate));
  }
  
  void updateComment(String? comment) {
    state = state.copyWith(comment: comment);
  }

  void restoreFromHistory(CalculationState historyState) {
    state = historyState;
  }
  
  CalculationState _recalculate(CalculationState currentState) {
    if (currentState.activeField == ActiveField.finalDate) {
      return _calculateDaysFromFinalDate(currentState);
    }
    return _calculateFinalDate(currentState);
  }

  CalculationState _calculateFinalDate(CalculationState currentState) {
    try {
      String finalExpression = currentState.daysExpression;
      if (finalExpression.endsWith('+') || finalExpression.endsWith('-')) {
        finalExpression = finalExpression.substring(0, finalExpression.length - 1);
      }
      if (finalExpression.isEmpty) {
        return currentState.copyWith(forceFinalDateNull: true);
      }
      
      final expression = ShuntingYardParser().parse(finalExpression);
      final evaluator = RealEvaluator(ContextModel());
      final days = evaluator.evaluate(expression).toInt();

      final finalDate = currentState.standardDate.add(Duration(days: days));
      return currentState.copyWith(finalDate: finalDate);
    } catch (e) {
      return currentState.copyWith(forceFinalDateNull: true);
    }
  }

  CalculationState _calculateDaysFromFinalDate(CalculationState currentState) {
    if (currentState.finalDate != null) {
      final daysDifference = currentState.finalDate!.difference(currentState.standardDate).inDays;
      return currentState.copyWith(daysExpression: daysDifference.toString());
    }
    return currentState;
  }
  
Future<void> saveHistory() async {
  if (state.finalDate == null) return;
  
  final settingsService = ref.read(settingsServiceProvider);
  List<CalculationState> history = settingsService.getHistory();
  
  // --- ▼▼▼ ここからが修正箇所 ▼▼▼ ---

  // 1. 保存されているポリシー設定を取得
  final policy = settingsService.getHistoryDuplicatePolicy();

  // 2. ポリシーに応じて重複チェックのロジックを分岐
  switch (policy) {
    case HistoryDuplicatePolicy.keepAll:
      // 何もせず、常に新しい履歴を追加する
      break;
    case HistoryDuplicatePolicy.removeSameComment:
      // コメントが同じ古い履歴を削除 (これまでの挙動)
      if (state.comment != null && state.comment!.isNotEmpty) {
        history.removeWhere((item) => item.comment == state.comment);
      }
      break;
    case HistoryDuplicatePolicy.removeSameCalculation:
      // コメント、基準日、日数表現がすべて一致する古い履歴を削除
      history.removeWhere((item) =>
        item.comment == state.comment &&
        item.standardDate == state.standardDate &&
        item.daysExpression == state.daysExpression
      );
      break;
  }
  
  // --- ▲▲▲ ここまでが修正箇所 ▲▲▲ ---
  
  history.insert(0, state);
  
  if (history.length > SettingsService.calculationHistoryLimit) {
    history.removeLast();
  }
  
  await settingsService.saveHistory(history);
  }
}