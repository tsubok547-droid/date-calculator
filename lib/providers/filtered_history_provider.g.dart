// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filtered_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredHistoryHash() => r'2c208d2c5723e3e240cffea326937374fa099a49';

/// フィルタリングされた履歴リストを提供するProvider
///
/// [historyNotifierProvider] (元の履歴) と [historyFilterNotifierProvider] (フィルター条件)
/// の状態を監視し、UIに表示すべきリストを生成する。
///
/// Copied from [filteredHistory].
@ProviderFor(filteredHistory)
final filteredHistoryProvider =
    AutoDisposeFutureProvider<List<CalculationState>>.internal(
      filteredHistory,
      name: r'filteredHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredHistoryRef =
    AutoDisposeFutureProviderRef<List<CalculationState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
