// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tray_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 桌面端系统托盘服务。

@ProviderFor(TrayNotifier)
final trayProvider = TrayNotifierProvider._();

/// 桌面端系统托盘服务。
final class TrayNotifierProvider
    extends $AsyncNotifierProvider<TrayNotifier, void> {
  /// 桌面端系统托盘服务。
  TrayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trayNotifierHash();

  @$internal
  @override
  TrayNotifier create() => TrayNotifier();
}

String _$trayNotifierHash() => r'13bc543e36823f454f601a5d2c90b04a9bf838fe';

/// 桌面端系统托盘服务。

abstract class _$TrayNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
