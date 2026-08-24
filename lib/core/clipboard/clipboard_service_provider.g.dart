// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 剪贴板核心服务

@ProviderFor(clipboardService)
final clipboardServiceProvider = ClipboardServiceProvider._();

/// 剪贴板核心服务

final class ClipboardServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardService>,
          ClipboardService,
          FutureOr<ClipboardService>
        >
    with $FutureModifier<ClipboardService>, $FutureProvider<ClipboardService> {
  /// 剪贴板核心服务
  ClipboardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardServiceHash();

  @$internal
  @override
  $FutureProviderElement<ClipboardService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClipboardService> create(Ref ref) {
    return clipboardService(ref);
  }
}

String _$clipboardServiceHash() => r'bc6ebe29125f65cdc36a65a2e9d2403053d50f14';

/// 剪贴板历史草稿事件流。
///
/// 历史模块订阅该 Provider 后再完成去重、规则、落库和同步。

@ProviderFor(clipboardHistoryEvents)
final clipboardHistoryEventsProvider = ClipboardHistoryEventsProvider._();

/// 剪贴板历史草稿事件流。
///
/// 历史模块订阅该 Provider 后再完成去重、规则、落库和同步。

final class ClipboardHistoryEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardHistoryEvent>,
          ClipboardHistoryEvent,
          Stream<ClipboardHistoryEvent>
        >
    with
        $FutureModifier<ClipboardHistoryEvent>,
        $StreamProvider<ClipboardHistoryEvent> {
  /// 剪贴板历史草稿事件流。
  ///
  /// 历史模块订阅该 Provider 后再完成去重、规则、落库和同步。
  ClipboardHistoryEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardHistoryEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardHistoryEventsHash();

  @$internal
  @override
  $StreamProviderElement<ClipboardHistoryEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ClipboardHistoryEvent> create(Ref ref) {
    return clipboardHistoryEvents(ref);
  }
}

String _$clipboardHistoryEventsHash() =>
    r'c99444b51521414e9ad92980f0f254c2594fd428';
