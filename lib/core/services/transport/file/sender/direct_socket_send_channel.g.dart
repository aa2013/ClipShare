// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_socket_send_channel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 直连通道：发送端开启临时数据端口并经会话发送控制消息，对端反连后传输文件流

@ProviderFor(DirectSocketSendChannel)
final directSocketSendChannelProvider = DirectSocketSendChannelProvider._();

/// 直连通道：发送端开启临时数据端口并经会话发送控制消息，对端反连后传输文件流
final class DirectSocketSendChannelProvider
    extends $NotifierProvider<DirectSocketSendChannel, void> {
  /// 直连通道：发送端开启临时数据端口并经会话发送控制消息，对端反连后传输文件流
  DirectSocketSendChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directSocketSendChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directSocketSendChannelHash();

  @$internal
  @override
  DirectSocketSendChannel create() => DirectSocketSendChannel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$directSocketSendChannelHash() =>
    r'24c3f3a626186acaae1a4ff823f090f1c4e4cbfc';

/// 直连通道：发送端开启临时数据端口并经会话发送控制消息，对端反连后传输文件流

abstract class _$DirectSocketSendChannel extends $Notifier<void> {
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
