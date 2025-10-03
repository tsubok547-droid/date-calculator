import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calculation_state.dart';
import '../models/history_filter_state.dart';
import '../screens/history_page.dart'; // isFilterActiveProvider をインポート
import 'history_filter_provider.dart';
import 'history_provider.dart';

part 'filtered_history_provider.g.dart';

/// フィルタリングされた履歴リストを提供するProvider
///
/// [historyNotifierProvider] (元の履歴) と [historyFilterNotifierProvider] (フィルター条件)
/// の状態を監視し、UIに表示すべきリストを生成する。
@riverpod
Future<List<CalculationState>> filteredHistory(Ref ref) async {
  // 元の履歴リスト（非同期）を監視
  final fullHistory = await ref.watch(historyNotifierProvider.future);
  
  // フィルターが有効でない場合は、元のリストをそのまま返す
  final isFilterActive = ref.watch(isFilterActiveProvider);
  if (!isFilterActive) {
    return fullHistory;
  }
  
  // フィルターが有効な場合は、条件に基づいて絞り込みを実行
  final filter = ref.watch(historyFilterNotifierProvider);
  
  return fullHistory.where((item) {
    final conditions = <bool>[];
    if (filter.comment != null && filter.comment!.isNotEmpty) {
      conditions.add(item.comment
              ?.toLowerCase()
              .contains(filter.comment!.toLowerCase()) ??
          false);
    }
    if (filter.standardDateStart != null || filter.standardDateEnd != null) {
      bool isInRange = true;
      if (filter.standardDateStart != null &&
          item.standardDate.isBefore(filter.standardDateStart!)) {
        isInRange = false;
      }
      if (filter.standardDateEnd != null &&
          item.standardDate
              .isAfter(filter.standardDateEnd!.add(const Duration(days: 1)))) {
        isInRange = false;
      }
      conditions.add(isInRange);
    }
    if (filter.finalDateStart != null || filter.finalDateEnd != null) {
      if (item.finalDate == null) {
        conditions.add(false);
      } else {
        bool isInRange = true;
        if (filter.finalDateStart != null &&
            item.finalDate!.isBefore(filter.finalDateStart!)) {
          isInRange = false;
        }
        if (filter.finalDateEnd != null &&
            item.finalDate!
                .isAfter(filter.finalDateEnd!.add(const Duration(days: 1)))) {
          isInRange = false;
        }
        conditions.add(isInRange);
      }
    }
    if (conditions.isEmpty) {
      return true;
    }
    if (filter.logic == FilterLogic.and) {
      return conditions.every((c) => c);
    } else {
      return conditions.any((c) => c);
    }
  }).toList();
}