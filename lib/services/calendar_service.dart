// lib/services/calendar_service.dart

import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/calculation_state.dart';

class CalendarService {
  Future<void> addEventToCalendar(CalculationState state) async {
    if (state.finalDate == null) return;

    final DateTime finalDate = state.finalDate!;
    final DateTime startTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 9);
    final DateTime endTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 10);

    final String finalTitle = '${state.comment ?? ""}最終日';

    final Event event = Event(
      title: finalTitle, // 修正したタイトルを設定
      startDate: startTime,
      endDate: endTime,
      timeZone: startTime.timeZoneName,
    );
    
    await Add2Calendar.addEvent2Cal(event);
  }
}