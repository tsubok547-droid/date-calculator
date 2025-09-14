import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/calculator_page.dart';
import 'providers/services_provider.dart';

// アプリ全体でSnackBarを管理するためのグローバルキー
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

class DateCalculatorApp extends ConsumerWidget {
  const DateCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsService = ref.watch(settingsServiceProvider);
    final primaryColor = settingsService.getPrimaryColor();
    final isJapaneseCalendar = settingsService.isJapaneseCalendar();

    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'くすりの日数計算機',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      // ▼▼▼ CalculatorPageの呼び出し部分を修正 ▼▼▼
      home: CalculatorPage(
        // onColorChanged: (color) => _changeColor(ref, color), // ← この行を削除
        isJapaneseCalendar: isJapaneseCalendar,
        onCalendarModeChanged: () => _toggleCalendarMode(ref),
      ),
    );
  }

  void _toggleCalendarMode(WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    final currentMode = settingsService.isJapaneseCalendar();
    settingsService.setJapaneseCalendar(!currentMode).then((_) {
      ref.invalidate(settingsServiceProvider);
    });
  }
}