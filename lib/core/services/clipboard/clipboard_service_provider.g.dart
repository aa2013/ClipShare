// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 剪贴板核心服务

@ProviderFor(ClipboardNotifier)
final clipboardProvider = ClipboardNotifierProvider._();

/// 剪贴板核心服务
final class ClipboardNotifierProvider
    extends $AsyncNotifierProvider<ClipboardNotifier, void> {
  /// 剪贴板核心服务
  ClipboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardNotifierHash();

  @$internal
  @override
  ClipboardNotifier create() => ClipboardNotifier();
}

String _$clipboardNotifierHash() => r'fd39835769603b3f9306e8dad8b632978871781e';

/// 剪贴板核心服务

abstract class _$ClipboardNotifier extends $AsyncNotifier<void> {
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
