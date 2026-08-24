// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'7119be732b6351147e3f29012fc6e5c02bd3f65e';
