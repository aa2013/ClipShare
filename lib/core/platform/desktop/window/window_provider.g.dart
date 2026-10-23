// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为、显示主窗口以及安全退出应用。

@ProviderFor(WindowNotifier)
final windowProvider = WindowNotifierProvider._();

/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为、显示主窗口以及安全退出应用。
final class WindowNotifierProvider
    extends $AsyncNotifierProvider<WindowNotifier, void> {
  /// 主窗口生命周期服务。
  ///
  /// 负责接管系统关闭行为、显示主窗口以及安全退出应用。
  WindowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowNotifierHash();

  @$internal
  @override
  WindowNotifier create() => WindowNotifier();
}

String _$windowNotifierHash() => r'3fec1ec6dbf0575fedae799f3aa81847564305b6';

/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为、显示主窗口以及安全退出应用。

abstract class _$WindowNotifier extends $AsyncNotifier<void> {
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
