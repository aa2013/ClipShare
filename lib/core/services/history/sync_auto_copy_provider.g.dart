// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_auto_copy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
///同步接收自动复制服务：统一收口"同步到本机的内容写剪贴板"的时机与资格。
///自主订阅历史 delta 流（仅同步落库的 add），不感知消息是实时同步还是补拉——
///补拉按最新到最旧发送，配合 latest 单调门天然只复制批次最新一条。

@ProviderFor(SyncAutoCopy)
final syncAutoCopyProvider = SyncAutoCopyProvider._();

///同步接收自动复制服务：统一收口"同步到本机的内容写剪贴板"的时机与资格。
///自主订阅历史 delta 流（仅同步落库的 add），不感知消息是实时同步还是补拉——
///补拉按最新到最旧发送，配合 latest 单调门天然只复制批次最新一条。
final class SyncAutoCopyProvider extends $NotifierProvider<SyncAutoCopy, void> {
  ///同步接收自动复制服务：统一收口"同步到本机的内容写剪贴板"的时机与资格。
  ///自主订阅历史 delta 流（仅同步落库的 add），不感知消息是实时同步还是补拉——
  ///补拉按最新到最旧发送，配合 latest 单调门天然只复制批次最新一条。
  SyncAutoCopyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncAutoCopyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncAutoCopyHash();

  @$internal
  @override
  SyncAutoCopy create() => SyncAutoCopy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncAutoCopyHash() => r'4be81c2147241e469bba3a5b7b2c486b28af28e4';

///同步接收自动复制服务：统一收口"同步到本机的内容写剪贴板"的时机与资格。
///自主订阅历史 delta 流（仅同步落库的 add），不感知消息是实时同步还是补拉——
///补拉按最新到最旧发送，配合 latest 单调门天然只复制批次最新一条。

abstract class _$SyncAutoCopy extends $Notifier<void> {
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
