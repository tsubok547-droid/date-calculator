// lib/providers/history_filter_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/history_filter_state.dart';

part 'history_filter_provider.g.dart';

@riverpod
class HistoryFilterNotifier extends _$HistoryFilterNotifier {
  @override
  HistoryFilterState build() {
    // 初期状態として、フィルターが何もかかっていない状態を返す
    return HistoryFilterState();
  }

  // フィルターの状態を更新するためのメソッド
  void updateFilter(HistoryFilterState newFilter) {
    state = newFilter;
  }

  // フィルターをリセットするためのメソッド
  void resetFilter() {
    state = HistoryFilterState();
  }
}