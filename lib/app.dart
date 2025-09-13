// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/calculator_page.dart';
import 'providers/services_provider.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

class DateCalculatorApp extends ConsumerWidget {
  const DateCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから設定を監視
    final settingsService = ref.watch(settingsServiceProvider);
    // テーマカラーとカレンダーモードはStateで管理（Appの再描画が必要なため）
    final primaryColor = settingsService.getPrimaryColor();
    final isJapaneseCalendar = settingsService.isJapaneseCalendar();

    return MaterialApp(
      title: '日付計算ツール',
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
      home: CalculatorPage(
        // コールバック関数を渡す
        onColorChanged: (color) => _changeColor(ref, color),
        isJapaneseCalendar: isJapaneseCalendar,
        onCalendarModeChanged: () => _toggleCalendarMode(ref),
      ),
    );
  }

  // 色変更のロジック
  void _changeColor(WidgetRef ref, Color color) {
    final settingsService = ref.read(settingsServiceProvider);
    settingsService.setPrimaryColor(color).then((_) {
      // 強制的に再ビルドを促すためにProviderを再読み込みさせる
      // 少しトリッキーですが、App全体の状態を更新する簡単な方法の一つ
      ref.invalidate(settingsServiceProvider);
    });
  }

  // カレンダーモード変更のロジック
  void _toggleCalendarMode(WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    final currentMode = settingsService.isJapaneseCalendar();
    settingsService.setJapaneseCalendar(!currentMode).then((_) {
      ref.invalidate(settingsServiceProvider);
    });
  }
}