// lib/providers/repositories_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart'; // AppDatabaseをインポート
import '../repositories/history_repository.dart';
import 'services_provider.dart';

// AppDatabaseのインスタンスをシングルトンとして提供するProvider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// HistoryRepositoryにAppDatabaseを渡してインスタンス化する
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  // HistoryRepositoryのコンストラクタが変更されたのに合わせて修正
  return HistoryRepository(db, settingsService);
});