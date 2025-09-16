// lib/services/calendar_service.dart

import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/calculation_state.dart';

class CalendarService {
  Future<void> addEventToCalendar(CalculationState state) async {
    if (state.finalDate == null) return;

    // ▼▼▼ ここから修正 ▼▼▼

    // URLや怪しい文字列を無害化する
    String sanitizedComment = state.comment ?? '';
    // http://, https://, www. で始まる文字列を削除する正規表現
    final urlPattern = RegExp(r'(https?:\/\/|www\.)\S+');
    // 見つかったURLを安全な文字列に置き換える
    sanitizedComment = sanitizedComment.replaceAll(urlPattern, '[URL削除済み]');

    final String finalTitle = '$sanitizedComment最終日';

    // ▲▲▲ ここまで修正 ▲▲▲


    final DateTime finalDate = state.finalDate!;
    final DateTime startTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 9);
    final DateTime endTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 10);

    final Event event = Event(
      title: finalTitle, // 修正したタイトルを設定
      startDate: startTime,
      endDate: endTime,
      timeZone: startTime.timeZoneName,
    );
    
    await Add2Calendar.addEvent2Cal(event);
  }
}