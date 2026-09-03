// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。

@ProviderFor(HistoriesNotifier)
final historiesProvider = HistoriesNotifierProvider._();

/// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。
final class HistoriesNotifierProvider
    extends $NotifierProvider<HistoriesNotifier, HistoryList> {
  /// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。
  HistoriesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historiesNotifierHash();

  @$internal
  @override
  HistoriesNotifier create() => HistoriesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryList value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryList>(value),
    );
  }
}

String _$historiesNotifierHash() => r'2f1cb1b46eb67cca72539a4b66232ea73f0feaef';

/// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。

abstract class _$HistoriesNotifier extends $Notifier<HistoryList> {
  HistoryList build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryList, HistoryList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryList, HistoryList>,
              HistoryList,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
