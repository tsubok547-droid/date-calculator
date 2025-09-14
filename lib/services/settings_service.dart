import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_state.dart';
import '../utils/constants.dart';

class SettingsService {
  late final SharedPreferences _prefs;

  static const List<int> defaultShortcuts = [7, 14, 28, 56, 84, 91];
  static const int searchHistoryLimit = 30;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- テーマカラー ---
  Color getPrimaryColor() {
    final colorValue = _prefs.getInt(PrefKeys.primaryColor) ?? Colors.indigo.value;
    return Color(colorValue);
  }

  Future<void> setPrimaryColor(Color color) async {
    await _prefs.setInt(PrefKeys.primaryColor, color.value);
  }

  // --- カレンダーモード ---
  bool isJapaneseCalendar() {
    return _prefs.getBool(PrefKeys.isJapaneseCalendar) ?? false;
  }

  Future<void> setJapaneseCalendar(bool isJapanese) async {
    await _prefs.setBool(PrefKeys.isJapaneseCalendar, isJapanese);
  }

  // --- ▼▼▼ カレンダー連携設定を追加 ▼▼▼ ---
  bool shouldAddEventToCalendar() {
    // デフォルトはON（true）
    return _prefs.getBool(PrefKeys.addEventToCalendar) ?? true;
  }

  Future<void> setAddEventToCalendar(bool isEnabled) async {
    await _prefs.setBool(PrefKeys.addEventToCalendar, isEnabled);
  }
  // --- ▲▲▲ ここまで ▲▲▲ ---

  // --- 計算履歴 ---
  List<CalculationState> getHistory() {
    final historyJson = _prefs.getStringList(PrefKeys.calcHistory) ?? [];
    try {
      return historyJson
          .map((json) => CalculationState.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      _prefs.remove(PrefKeys.calcHistory);
      return [];
    }
  }

  Future<void> saveHistory(List<CalculationState> history) async {
    List<String> historyJson =
        history.map((state) => jsonEncode(state.toJson())).toList();
    await _prefs.setStringList(PrefKeys.calcHistory, historyJson);
  }
  
  Future<void> clearHistory() async {
    await _prefs.remove(PrefKeys.calcHistory);
  }

  // --- ショートカット設定 ---
  List<int> getShortcutValues() {
    final savedValues = _prefs.getStringList(PrefKeys.shortcutValues);
    if (savedValues == null) {
      return defaultShortcuts;
    }
    return savedValues.map((s) => int.parse(s)).toList();
  }

  Future<void> saveShortcutValues(List<int> values) async {
    final stringValues = values.map((i) => i.toString()).toList();
    await _prefs.setStringList(PrefKeys.shortcutValues, stringValues);
  }

  Future<void> restoreDefaultShortcuts() async {
    await _prefs.remove(PrefKeys.shortcutValues);
  }

  // --- 検索履歴 ---
  List<String> getSearchHistory() {
    return _prefs.getStringList(PrefKeys.searchHistory) ?? [];
  }

  Future<void> addSearchTerm(String term) async {
    if (term.isEmpty) return;
    
    List<String> history = getSearchHistory();

    history.removeWhere((item) => item.toLowerCase() == term.toLowerCase());
    history.insert(0, term);

    if (history.length > searchHistoryLimit) {
      history.removeLast();
    }
    
    await _prefs.setStringList(PrefKeys.searchHistory, history);
  }
}