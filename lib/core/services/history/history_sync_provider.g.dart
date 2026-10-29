// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 历史记录同步处理器

@ProviderFor(HistorySyncNotifier)
final historySyncProvider = HistorySyncNotifierProvider._();

/// 历史记录同步处理器
final class HistorySyncNotifierProvider
    extends $NotifierProvider<HistorySyncNotifier, void> {
  /// 历史记录同步处理器
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
    r'db82ee4fa60c2b4c5fa9b8eb3a3759182c98d78c';

/// 历史记录同步处理器

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
