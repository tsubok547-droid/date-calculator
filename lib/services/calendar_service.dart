import 'package:url_launcher/url_launcher.dart';
import '../models/calculation_state.dart';
import './messenger_service.dart'; // 新しいメッセンジャーサービスをインポート
import '../app.dart'; // app.dartをインポートしてキーにアクセス

class CalendarService {
  final _messengerService = MessengerService();

  Future<void> addEventToCalendar(CalculationState state) async { 
    if (state.finalDate == null) return;

    final DateTime startTime = state.finalDate!;
    final DateTime endTime = startTime.add(const Duration(hours: 1));
    final String title = state.comment ?? '計算結果の日付';
    
    final Uri calendarUrl = Uri.parse(
      'https://ical.marudot.com/?title=${Uri.encodeComponent(title)}&start=${_formatDateForUrl(startTime)}&end=${_formatDateForUrl(endTime)}'
    );

    if (await canLaunchUrl(calendarUrl)) {
      await launchUrl(calendarUrl);
    } else {
      // GlobalKeyを直接渡す
      _messengerService.showSnackBar(messengerKey, 'カレンダーアプリを開けませんでした。');
    }
  }

  String _formatDateForUrl(DateTime date) {
    return date.toIso8601String().split('.').first;
  }
}
