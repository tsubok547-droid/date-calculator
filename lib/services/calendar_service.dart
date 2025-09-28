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
    // 日本の午前9時がUTCで何時になるかを計算して設定します (JSTはUTC+9時間なので、9-9=0)
    final DateTime startTime = DateTime.utc(finalDate.year, finalDate.month, finalDate.day, 0);
    // 同様に、日本の午前10時はUTCの午前1時です (10-9=1)
    final DateTime endTime = DateTime.utc(finalDate.year, finalDate.month, finalDate.day, 1);

    final Event event = Event(
      title: finalTitle,
      startDate: startTime,
      endDate: endTime,
      timeZone: startTime.timeZoneName,
    );
    
    await Add2Calendar.addEvent2Cal(event);
  }
}