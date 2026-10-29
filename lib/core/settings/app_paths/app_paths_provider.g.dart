// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_paths_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appPaths)
final appPathsProvider = AppPathsProvider._();

final class AppPathsProvider
    extends
        $FunctionalProvider<AsyncValue<AppPaths>, AppPaths, FutureOr<AppPaths>>
    with $FutureModifier<AppPaths>, $FutureProvider<AppPaths> {
  AppPathsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPathsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPathsHash();

  @$internal
  @override
  $FutureProviderElement<AppPaths> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppPaths> create(Ref ref) {
    return appPaths(ref);
  }
}

String _$appPathsHash() => r'ba072865b3d3b61520db320f5b6e99e914cfea1b';
