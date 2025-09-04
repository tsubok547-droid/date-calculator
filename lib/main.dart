// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/settings_service.dart';
import 'providers/services_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  // 設定サービスクラスを初期化
  final settingsService = SettingsService();
  await settingsService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(
    // アプリ全体をProviderScopeで囲む
    ProviderScope(
      overrides: [
        // settingsServiceProviderの初期値をここで設定
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const DateCalculatorApp(),
    ),
  );
}