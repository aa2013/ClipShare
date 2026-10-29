// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_status_event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 中转状态广播：中转服务与存储中转只负责发出事件，
/// 观察方通过 [ForwardStatusEventNotifier.forwardStatusEvents] 订阅。

@ProviderFor(ForwardStatusEventNotifier)
final forwardStatusEventProvider = ForwardStatusEventNotifierProvider._();

/// 中转状态广播：中转服务与存储中转只负责发出事件，
/// 观察方通过 [ForwardStatusEventNotifier.forwardStatusEvents] 订阅。
final class ForwardStatusEventNotifierProvider
    extends $NotifierProvider<ForwardStatusEventNotifier, void> {
  /// 中转状态广播：中转服务与存储中转只负责发出事件，
  /// 观察方通过 [ForwardStatusEventNotifier.forwardStatusEvents] 订阅。
  ForwardStatusEventNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardStatusEventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardStatusEventNotifierHash();

  @$internal
  @override
  ForwardStatusEventNotifier create() => ForwardStatusEventNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$forwardStatusEventNotifierHash() =>
    r'ce20573607241b6df275bd086aeda642af08e7f8';

/// 中转状态广播：中转服务与存储中转只负责发出事件，
/// 观察方通过 [ForwardStatusEventNotifier.forwardStatusEvents] 订阅。

abstract class _$ForwardStatusEventNotifier extends $Notifier<void> {
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
