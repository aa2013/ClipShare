// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_push_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 负责把本地操作记录补全为同步载荷并推送给对端，
/// 与接收侧的 [MessageSyncNotifier] 事件流成对存在。

@ProviderFor(SyncPushNotifier)
final syncPushProvider = SyncPushNotifierProvider._();

/// 负责把本地操作记录补全为同步载荷并推送给对端，
/// 与接收侧的 [MessageSyncNotifier] 事件流成对存在。
final class SyncPushNotifierProvider
    extends $NotifierProvider<SyncPushNotifier, void> {
  /// 负责把本地操作记录补全为同步载荷并推送给对端，
  /// 与接收侧的 [MessageSyncNotifier] 事件流成对存在。
  SyncPushNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncPushProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncPushNotifierHash();

  @$internal
  @override
  SyncPushNotifier create() => SyncPushNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncPushNotifierHash() => r'5199d886fee458d0926b6a8c9f28bf2ae77303ab';

/// 负责把本地操作记录补全为同步载荷并推送给对端，
/// 与接收侧的 [MessageSyncNotifier] 事件流成对存在。

abstract class _$SyncPushNotifier extends $Notifier<void> {
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
