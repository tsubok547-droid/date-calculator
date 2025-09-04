// lib/providers/services_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

// このProviderを通してSettingsServiceのインスタンスにアクセスする
final settingsServiceProvider = Provider<SettingsService>((ref) {
  // main.dartで上書きされるため、ここではエラーを投げる
  throw UnimplementedError();
});