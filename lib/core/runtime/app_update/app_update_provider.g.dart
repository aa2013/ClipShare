// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 无界面的更新运行时，统一调度、并发检查与结果广播。

@ProviderFor(AppUpdateNotifier)
final appUpdateProvider = AppUpdateNotifierProvider._();

/// 无界面的更新运行时，统一调度、并发检查与结果广播。
final class AppUpdateNotifierProvider
    extends $NotifierProvider<AppUpdateNotifier, void> {
  /// 无界面的更新运行时，统一调度、并发检查与结果广播。
  AppUpdateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateNotifierHash();

  @$internal
  @override
  AppUpdateNotifier create() => AppUpdateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appUpdateNotifierHash() => r'5fa2f603cd877a912aa83ae99996b144685a009d';

/// 无界面的更新运行时，统一调度、并发检查与结果广播。

abstract class _$AppUpdateNotifier extends $Notifier<void> {
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
