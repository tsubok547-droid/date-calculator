// lib/utils/constants.dart

// SharedPreferencesで使用するキー
abstract class PrefKeys {
  static const String primaryColor = 'primaryColor';
  static const String isJapaneseCalendar = 'isJapaneseCalendar';
  static const String addEventToCalendar = 'addEventToCalendar';
  static const String calcHistory = 'calcHistory';
  static const String shortcutValues = 'shortcutValues';
  static const String searchHistory = 'searchHistory';
  static const String historyDuplicatePolicy = 'historyDuplicatePolicy';
}

// アプリ全体で共有する設定値
abstract class AppConstants {
  // 日付ピッカーの有効期間
  static final DateTime minDate = DateTime(1926);
  static final DateTime maxDate = DateTime(2101);

  // 履歴の最大保存件数
  static const int calculationHistoryLimit = 500;
  static const int searchHistoryLimit = 30;

  // キーパッドの特殊キー
  static const String keyEnter = 'Ent';
  static const String keyClear = 'C';
  static const String keyBackspace = '←';
}