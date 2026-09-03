// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 剪贴板核心服务

@ProviderFor(clipboardService)
final clipboardServiceProvider = ClipboardServiceProvider._();

/// 剪贴板核心服务

final class ClipboardServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardService>,
          ClipboardService,
          FutureOr<ClipboardService>
        >
    with $FutureModifier<ClipboardService>, $FutureProvider<ClipboardService> {
  /// 剪贴板核心服务
  ClipboardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardServiceHash();

  @$internal
  @override
  $FutureProviderElement<ClipboardService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClipboardService> create(Ref ref) {
    return clipboardService(ref);
  }
}

String _$clipboardServiceHash() => r'aa10e7bef0204cfcc461a31e11501965f85e7e3b';
