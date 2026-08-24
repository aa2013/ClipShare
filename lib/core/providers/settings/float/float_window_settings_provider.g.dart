// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'float_window_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(floatWindowSettings)
final floatWindowSettingsProvider = FloatWindowSettingsProvider._();

final class FloatWindowSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<FloatWindowSettings>,
          FloatWindowSettings,
          FutureOr<FloatWindowSettings>
        >
    with
        $FutureModifier<FloatWindowSettings>,
        $FutureProvider<FloatWindowSettings> {
  FloatWindowSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'floatWindowSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$floatWindowSettingsHash();

  @$internal
  @override
  $FutureProviderElement<FloatWindowSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FloatWindowSettings> create(Ref ref) {
    return floatWindowSettings(ref);
  }
}

String _$floatWindowSettingsHash() =>
    r'bac8c5de920786c3937ca63166ad3a8600f0d375';
