// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_module_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 脚本模块同步处理器。

@ProviderFor(ScriptModuleSyncNotifier)
final scriptModuleSyncProvider = ScriptModuleSyncNotifierProvider._();

/// 脚本模块同步处理器。
final class ScriptModuleSyncNotifierProvider
    extends $NotifierProvider<ScriptModuleSyncNotifier, void> {
  /// 脚本模块同步处理器。
  ScriptModuleSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scriptModuleSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scriptModuleSyncNotifierHash();

  @$internal
  @override
  ScriptModuleSyncNotifier create() => ScriptModuleSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$scriptModuleSyncNotifierHash() =>
    r'0854347c60e899ce0bf4638042ae0ab5e5d3dc59';

/// 脚本模块同步处理器。

abstract class _$ScriptModuleSyncNotifier extends $Notifier<void> {
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
