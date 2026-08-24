// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_window_args_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前窗口的多窗口启动参数；主窗口为 null，子窗口由启动时 override。

@ProviderFor(multiWindowArgs)
final multiWindowArgsProvider = MultiWindowArgsProvider._();

/// 当前窗口的多窗口启动参数；主窗口为 null，子窗口由启动时 override。

final class MultiWindowArgsProvider
    extends
        $FunctionalProvider<
          DesktopMultiWindowArgs?,
          DesktopMultiWindowArgs?,
          DesktopMultiWindowArgs?
        >
    with $Provider<DesktopMultiWindowArgs?> {
  /// 当前窗口的多窗口启动参数；主窗口为 null，子窗口由启动时 override。
  MultiWindowArgsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiWindowArgsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiWindowArgsHash();

  @$internal
  @override
  $ProviderElement<DesktopMultiWindowArgs?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DesktopMultiWindowArgs? create(Ref ref) {
    return multiWindowArgs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopMultiWindowArgs? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopMultiWindowArgs?>(value),
    );
  }
}

String _$multiWindowArgsHash() => r'b46ba73493d6852678a80368850e58463d7f6deb';
