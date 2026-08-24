// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主窗口生命周期服务 keepAlive 单例装配。
///
/// 服务本身无可观察状态，此处仅负责：配置取值器注入（每次读取最新值）、
/// 生命周期挂载（ref.onDispose）、启动时接管系统关闭行为。

@ProviderFor(windowService)
final windowServiceProvider = WindowServiceProvider._();

/// 主窗口生命周期服务 keepAlive 单例装配。
///
/// 服务本身无可观察状态，此处仅负责：配置取值器注入（每次读取最新值）、
/// 生命周期挂载（ref.onDispose）、启动时接管系统关闭行为。

final class WindowServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<WindowService>,
          WindowService,
          FutureOr<WindowService>
        >
    with $FutureModifier<WindowService>, $FutureProvider<WindowService> {
  /// 主窗口生命周期服务 keepAlive 单例装配。
  ///
  /// 服务本身无可观察状态，此处仅负责：配置取值器注入（每次读取最新值）、
  /// 生命周期挂载（ref.onDispose）、启动时接管系统关闭行为。
  WindowServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowServiceHash();

  @$internal
  @override
  $FutureProviderElement<WindowService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WindowService> create(Ref ref) {
    return windowService(ref);
  }
}

String _$windowServiceHash() => r'186443c915f61a1c7adaaa395c16b272d8ec2910';
