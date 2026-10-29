// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_window_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 子窗口配置：启动参数初始化，并监听主窗口 [MultiWindowMethod.updateConfig] 推送。

@ProviderFor(MultiWindowConfigNotifier)
final multiWindowConfigProvider = MultiWindowConfigNotifierProvider._();

/// 子窗口配置：启动参数初始化，并监听主窗口 [MultiWindowMethod.updateConfig] 推送。
final class MultiWindowConfigNotifierProvider
    extends
        $NotifierProvider<MultiWindowConfigNotifier, MultiWindowConfigState> {
  /// 子窗口配置：启动参数初始化，并监听主窗口 [MultiWindowMethod.updateConfig] 推送。
  MultiWindowConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiWindowConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiWindowConfigNotifierHash();

  @$internal
  @override
  MultiWindowConfigNotifier create() => MultiWindowConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MultiWindowConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MultiWindowConfigState>(value),
    );
  }
}

String _$multiWindowConfigNotifierHash() =>
    r'b656c5893321af60b8cf8fd18e521e257993d880';

/// 子窗口配置：启动参数初始化，并监听主窗口 [MultiWindowMethod.updateConfig] 推送。

abstract class _$MultiWindowConfigNotifier
    extends $Notifier<MultiWindowConfigState> {
  MultiWindowConfigState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<MultiWindowConfigState, MultiWindowConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MultiWindowConfigState, MultiWindowConfigState>,
              MultiWindowConfigState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
