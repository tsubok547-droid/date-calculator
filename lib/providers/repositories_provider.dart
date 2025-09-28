// lib/providers/repositories_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/history_repository.dart';
import 'services_provider.dart';

final historyRepositoryProvider = FutureProvider<HistoryRepository>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  final repository = HistoryRepository(settingsService);
  await repository.init(); // 初期化処理を追加
  return repository;
});