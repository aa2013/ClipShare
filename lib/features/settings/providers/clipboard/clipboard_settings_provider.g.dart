// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clipboardSettings)
final clipboardSettingsProvider = ClipboardSettingsProvider._();

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

String _$clipboardSettingsHash() => r'ecbee64e1e4acf4b9cd85986fe18a530a514a1cf';
