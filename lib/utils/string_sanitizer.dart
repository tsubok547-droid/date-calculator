// lib/utils/string_sanitizer.dart

/// テキストをカレンダーのタイトル用に無害化します。
/// URLなどの不要な情報を取り除きます。
String sanitizeForCalendar(String? text) {
  if (text == null || text.isEmpty) return '';

  final urlPattern = RegExp(r'(https?:\/\/|www\.)\S+');
  return text.replaceAll(urlPattern, '[URL削除済み]');
}

/// テキストをCSV出力用に無害化します。
/// CSVインジェクションを防ぐため、特定の文字で始まる文字列をエスケープします。
String sanitizeForCsv(String? input) {
  if (input == null || input.isEmpty) return '';

  if (input.startsWith('=') ||
      input.startsWith('+') ||
      input.startsWith('-') ||
      input.startsWith('@')) {
    return "'$input";
  }
  return input;
}