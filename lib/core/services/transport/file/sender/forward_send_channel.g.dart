// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_send_channel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 中转通道：向中转服务器发起文件连接，等待接收端就绪后传输文件流

@ProviderFor(ForwardSendChannel)
final forwardSendChannelProvider = ForwardSendChannelProvider._();

/// 中转通道：向中转服务器发起文件连接，等待接收端就绪后传输文件流
final class ForwardSendChannelProvider
    extends $NotifierProvider<ForwardSendChannel, void> {
  /// 中转通道：向中转服务器发起文件连接，等待接收端就绪后传输文件流
  ForwardSendChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardSendChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardSendChannelHash();

  @$internal
  @override
  ForwardSendChannel create() => ForwardSendChannel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$forwardSendChannelHash() =>
    r'5340b5c325955e84769de33e025565b6405fcaff';

/// 中转通道：向中转服务器发起文件连接，等待接收端就绪后传输文件流

abstract class _$ForwardSendChannel extends $Notifier<void> {
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
