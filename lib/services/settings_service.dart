// lib/services/settings_service.dart

import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_state.dart';
import '../utils/constants.dart';

class SettingsService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // テーマカラー
  Color getPrimaryColor() {
    final colorValue = _prefs.getInt(PrefKeys.primaryColor) ?? 0xFF3F51B5;
    return Color(colorValue);
  }

  Future<void> setPrimaryColor(Color color) async {
    // ignore: deprecated_member_use
    await _prefs.setInt(PrefKeys.primaryColor, color.value);
  }

  // カレンダーモード
  bool isJapaneseCalendar() {
    return _prefs.getBool(PrefKeys.isJapaneseCalendar) ?? false;
  }

  Future<void> setJapaneseCalendar(bool isJapanese) async {
    await _prefs.setBool(PrefKeys.isJapaneseCalendar, isJapanese);
  }

  // 計算履歴
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
}