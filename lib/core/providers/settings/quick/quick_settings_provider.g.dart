// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quickSettings)
final quickSettingsProvider = QuickSettingsProvider._();

final class QuickSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickSettings>,
          QuickSettings,
          FutureOr<QuickSettings>
        >
    with $FutureModifier<QuickSettings>, $FutureProvider<QuickSettings> {
  QuickSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickSettingsHash();

  @$internal
  @override
  $FutureProviderElement<QuickSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickSettings> create(Ref ref) {
    return quickSettings(ref);
  }
}

String _$quickSettingsHash() => r'089e4062cde8cce71749dd0594199b454b52443c';
