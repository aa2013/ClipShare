// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_recorder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 暴露为全局单例服务，不持有任何 UI 状态

@ProviderFor(historyRecorder)
final historyRecorderProvider = HistoryRecorderProvider._();

/// 暴露为全局单例服务，不持有任何 UI 状态

final class HistoryRecorderProvider
    extends
        $FunctionalProvider<HistoryRecorder, HistoryRecorder, HistoryRecorder>
    with $Provider<HistoryRecorder> {
  /// 暴露为全局单例服务，不持有任何 UI 状态
  HistoryRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRecorderHash();

  @$internal
  @override
  $ProviderElement<HistoryRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryRecorder create(Ref ref) {
    return historyRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryRecorder>(value),
    );
  }
}

String _$historyRecorderHash() => r'0f898232aaadf9f4563027700955d9924d3f62e6';
