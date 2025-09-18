// lib/providers/repositories_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/history_repository.dart';
import 'services_provider.dart';

/// HistoryRepository のインスタンスを提供する Provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  // SettingsService を受け取って HistoryRepository を初期化する
  final settingsService = ref.watch(settingsServiceProvider);
  return HistoryRepository(settingsService);
});