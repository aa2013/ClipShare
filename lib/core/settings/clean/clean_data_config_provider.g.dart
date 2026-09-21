// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_data_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CleanDataConfigNotifier)
final cleanDataConfigProvider = CleanDataConfigNotifierProvider._();

final class CleanDataConfigNotifierProvider
    extends $AsyncNotifierProvider<CleanDataConfigNotifier, CleanDataConfig?> {
  CleanDataConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cleanDataConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cleanDataConfigNotifierHash();

  @$internal
  @override
  CleanDataConfigNotifier create() => CleanDataConfigNotifier();
}

String _$cleanDataConfigNotifierHash() =>
    r'df905bbe4aa09b7fd902b73085db25e321366485';

abstract class _$CleanDataConfigNotifier
    extends $AsyncNotifier<CleanDataConfig?> {
  FutureOr<CleanDataConfig?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CleanDataConfig?>, CleanDataConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CleanDataConfig?>, CleanDataConfig?>,
              AsyncValue<CleanDataConfig?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
