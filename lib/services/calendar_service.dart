import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/calculation_state.dart';
import '../utils/string_sanitizer.dart'; // 共通ユーティリティをインポート

class CalendarService {
  Future<void> addEventToCalendar(CalculationState state) async {
    if (state.finalDate == null) return;

    // 共通関数を呼び出してコメントを無害化
    final sanitizedComment = sanitizeForCalendar(state.comment);
    final String finalTitle = '$sanitizedComment最終日';

    final DateTime finalDate = state.finalDate!;
    final DateTime startTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 9);
    final DateTime endTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 10);

    final Event event = Event(
      title: finalTitle,
      startDate: startTime,
      endDate: endTime,
      timeZone: startTime.timeZoneName,
    );
    
    await Add2Calendar.addEvent2Cal(event);
  }
}