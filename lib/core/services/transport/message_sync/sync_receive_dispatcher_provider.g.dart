// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_receive_dispatcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步消息接收分发层。
///
/// 只负责把网络载荷解析为强类型事件并投递到事件流，
/// 不执行业务处理、不发送确认；确认由模块处理成功后统一收口。

@ProviderFor(SyncReceiveDispatcher)
final syncReceiveDispatcherProvider = SyncReceiveDispatcherProvider._();

/// 同步消息接收分发层。
///
/// 只负责把网络载荷解析为强类型事件并投递到事件流，
/// 不执行业务处理、不发送确认；确认由模块处理成功后统一收口。
final class SyncReceiveDispatcherProvider
    extends $NotifierProvider<SyncReceiveDispatcher, void> {
  /// 同步消息接收分发层。
  ///
  /// 只负责把网络载荷解析为强类型事件并投递到事件流，
  /// 不执行业务处理、不发送确认；确认由模块处理成功后统一收口。
  SyncReceiveDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncReceiveDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncReceiveDispatcherHash();

  @$internal
  @override
  SyncReceiveDispatcher create() => SyncReceiveDispatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncReceiveDispatcherHash() =>
    r'93cb98f4144524aa407c7bf92b62640ae2da804e';

/// 同步消息接收分发层。
///
/// 只负责把网络载荷解析为强类型事件并投递到事件流，
/// 不执行业务处理、不发送确认；确认由模块处理成功后统一收口。

abstract class _$SyncReceiveDispatcher extends $Notifier<void> {
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
