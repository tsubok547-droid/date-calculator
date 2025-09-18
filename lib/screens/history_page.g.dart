// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isFilterActiveHash() => r'343cf98abfce170404b1e1adc2a9396a5c5c5581';

/// フィルターがアクティブかどうかを判定するProvider
///
/// Copied from [isFilterActive].
@ProviderFor(isFilterActive)
final isFilterActiveProvider = AutoDisposeProvider<bool>.internal(
  isFilterActive,
  name: r'isFilterActiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isFilterActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsFilterActiveRef = AutoDisposeProviderRef<bool>;
String _$filteredHistoryHash() => r'90a359977efc2a2801186f6b3fc88bbb9cacb1df';

/// フィルターされた履歴リストを提供するProvider
///
/// Copied from [filteredHistory].
@ProviderFor(filteredHistory)
final filteredHistoryProvider =
    AutoDisposeProvider<List<CalculationState>>.internal(
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
typedef FilteredHistoryRef = AutoDisposeProviderRef<List<CalculationState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
