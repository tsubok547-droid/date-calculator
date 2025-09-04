// lib/utils/date_formatter.dart

import 'package:intl/intl.dart';
import 'package:japanese_date_converter/japanese_date_converter.dart';

enum DateFormatStyle {
  full,
  compact,
}

String formatDate(DateTime? date, {
  required bool isJapanese,
  required DateFormatStyle style,
}) {
  if (date == null) {
    return style == DateFormatStyle.full ? '----年--月--日(-)' : '----/--/--';
  }

  if (isJapanese) {
    final japaneseDateString = date.toJapaneseDateString();
    if (style == DateFormatStyle.compact) {
      return japaneseDateString.split('(').first;
    }
    return japaneseDateString;
  } else {
    final formatPattern =
        style == DateFormatStyle.full ? 'yyyy年M月d日(E)' : 'yyyy/MM/dd';
    return DateFormat(formatPattern, 'ja_JP').format(date);
  }
}