// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 接收对端下发的历史记录同步事件，落库成功后回确认。

@ProviderFor(HistorySyncNotifier)
final historySyncProvider = HistorySyncNotifierProvider._();

/// 接收对端下发的历史记录同步事件，落库成功后回确认。
final class HistorySyncNotifierProvider
    extends $NotifierProvider<HistorySyncNotifier, void> {
  /// 接收对端下发的历史记录同步事件，落库成功后回确认。
  HistorySyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historySyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historySyncNotifierHash();

  @$internal
  @override
  HistorySyncNotifier create() => HistorySyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$historySyncNotifierHash() =>
    r'812399821eaa7fa4533f1891eee87c04a32c5516';

/// 接收对端下发的历史记录同步事件，落库成功后回确认。

abstract class _$HistorySyncNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
