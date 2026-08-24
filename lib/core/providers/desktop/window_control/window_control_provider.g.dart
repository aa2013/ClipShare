// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_control_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 桌面端窗体控制（最大化/最小化/关闭等）运行时能力。

@ProviderFor(WindowControlNotifier)
final windowControlProvider = WindowControlNotifierProvider._();

/// 桌面端窗体控制（最大化/最小化/关闭等）运行时能力。
final class WindowControlNotifierProvider
    extends $NotifierProvider<WindowControlNotifier, WindowControlState> {
  /// 桌面端窗体控制（最大化/最小化/关闭等）运行时能力。
  WindowControlNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowControlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowControlNotifierHash();

  @$internal
  @override
  WindowControlNotifier create() => WindowControlNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowControlState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowControlState>(value),
    );
  }
}

String _$windowControlNotifierHash() =>
    r'6f1795d94255b7153e66568c26372b3ca31cdc50';

/// 桌面端窗体控制（最大化/最小化/关闭等）运行时能力。

abstract class _$WindowControlNotifier extends $Notifier<WindowControlState> {
  WindowControlState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WindowControlState, WindowControlState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WindowControlState, WindowControlState>,
              WindowControlState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
