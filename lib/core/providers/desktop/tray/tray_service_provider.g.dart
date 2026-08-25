// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tray_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 托盘服务 keepAlive 单例装配。

@ProviderFor(trayService)
final trayServiceProvider = TrayServiceProvider._();

/// 托盘服务 keepAlive 单例装配。

final class TrayServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrayService>,
          TrayService,
          FutureOr<TrayService>
        >
    with $FutureModifier<TrayService>, $FutureProvider<TrayService> {
  /// 托盘服务 keepAlive 单例装配。
  TrayServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trayServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trayServiceHash();

  @$internal
  @override
  $FutureProviderElement<TrayService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrayService> create(Ref ref) {
    return trayService(ref);
  }
}

String _$trayServiceHash() => r'c9f5fe49b05699486ee3881467267c9332b85609';
