// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 读取剪贴板相关配置。

@ProviderFor(clipboardSettings)
final clipboardSettingsProvider = ClipboardSettingsProvider._();

/// 读取剪贴板相关配置。

final class ClipboardSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardSettings>,
          ClipboardSettings,
          FutureOr<ClipboardSettings>
        >
    with
        $FutureModifier<ClipboardSettings>,
        $FutureProvider<ClipboardSettings> {
  /// 读取剪贴板相关配置。
  ClipboardSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardSettingsHash();

  @$internal
  @override
  $FutureProviderElement<ClipboardSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClipboardSettings> create(Ref ref) {
    return clipboardSettings(ref);
  }
}

String _$clipboardSettingsHash() => r'1eef96d3b48e3a186e94a908a6ad3d3b2993b2d5';
