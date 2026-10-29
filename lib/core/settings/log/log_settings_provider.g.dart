// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(logSettings)
final logSettingsProvider = LogSettingsProvider._();

final class LogSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LogSettings>,
          LogSettings,
          FutureOr<LogSettings>
        >
    with $FutureModifier<LogSettings>, $FutureProvider<LogSettings> {
  LogSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logSettingsHash();

  @$internal
  @override
  $FutureProviderElement<LogSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LogSettings> create(Ref ref) {
    return logSettings(ref);
  }
}

String _$logSettingsHash() => r'ee3696a808447c4d4bc2f04a68ba7bad1f1e8af4';
