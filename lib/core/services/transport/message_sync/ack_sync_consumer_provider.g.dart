// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ack_sync_consumer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步确认的统一收口。
///
/// 出站：本机处理成功的模块产出的待确认事件在此统一发给对端；
/// 入站：对端回传的确认在此登记，供发送端补数时跳过已同步记录。

@ProviderFor(AckSyncConsumer)
final ackSyncConsumerProvider = AckSyncConsumerProvider._();

/// 同步确认的统一收口。
///
/// 出站：本机处理成功的模块产出的待确认事件在此统一发给对端；
/// 入站：对端回传的确认在此登记，供发送端补数时跳过已同步记录。
final class AckSyncConsumerProvider
    extends $NotifierProvider<AckSyncConsumer, void> {
  /// 同步确认的统一收口。
  ///
  /// 出站：本机处理成功的模块产出的待确认事件在此统一发给对端；
  /// 入站：对端回传的确认在此登记，供发送端补数时跳过已同步记录。
  AckSyncConsumerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ackSyncConsumerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ackSyncConsumerHash();

  @$internal
  @override
  AckSyncConsumer create() => AckSyncConsumer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$ackSyncConsumerHash() => r'8c0edec747c2fdc5d537076768d47bddc12fbe3e';

/// 同步确认的统一收口。
///
/// 出站：本机处理成功的模块产出的待确认事件在此统一发给对端；
/// 入站：对端回传的确认在此登记，供发送端补数时跳过已同步记录。

abstract class _$AckSyncConsumer extends $Notifier<void> {
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
