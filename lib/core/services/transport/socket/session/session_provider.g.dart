// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 设备会话的公开入口。

@ProviderFor(SessionNotifier)
final sessionProvider = SessionNotifierProvider._();

/// 设备会话的公开入口。
final class SessionNotifierProvider
    extends $NotifierProvider<SessionNotifier, void> {
  /// 设备会话的公开入口。
  SessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionNotifierHash();

  @$internal
  @override
  SessionNotifier create() => SessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sessionNotifierHash() => r'2bc384e4085bb1080256fb91360b21d45b4e3255';

/// 设备会话的公开入口。

abstract class _$SessionNotifier extends $Notifier<void> {
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

/// 维护正在建立连接的设备 guid 集合，供界面展示"连接中"标记。
/// 由 SessionNotifier 在提交连接候选时维护，覆盖排队、探活和握手的完整过程。

@ProviderFor(DeviceConnectingNotifier)
final deviceConnectingProvider = DeviceConnectingNotifierProvider._();

/// 维护正在建立连接的设备 guid 集合，供界面展示"连接中"标记。
/// 由 SessionNotifier 在提交连接候选时维护，覆盖排队、探活和握手的完整过程。
final class DeviceConnectingNotifierProvider
    extends $NotifierProvider<DeviceConnectingNotifier, Set<String>> {
  /// 维护正在建立连接的设备 guid 集合，供界面展示"连接中"标记。
  /// 由 SessionNotifier 在提交连接候选时维护，覆盖排队、探活和握手的完整过程。
  DeviceConnectingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceConnectingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceConnectingNotifierHash();

  @$internal
  @override
  DeviceConnectingNotifier create() => DeviceConnectingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$deviceConnectingNotifierHash() =>
    r'20afca778d96e23143570a8a1a09a5be2a979ee9';

/// 维护正在建立连接的设备 guid 集合，供界面展示"连接中"标记。
/// 由 SessionNotifier 在提交连接候选时维护，覆盖排队、探活和握手的完整过程。

abstract class _$DeviceConnectingNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
