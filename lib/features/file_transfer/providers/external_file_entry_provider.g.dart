// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_file_entry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExternalFileEntryNotifier)
final externalFileEntryProvider = ExternalFileEntryNotifierProvider._();

final class ExternalFileEntryNotifierProvider
    extends $NotifierProvider<ExternalFileEntryNotifier, void> {
  ExternalFileEntryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalFileEntryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalFileEntryNotifierHash();

  @$internal
  @override
  ExternalFileEntryNotifier create() => ExternalFileEntryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$externalFileEntryNotifierHash() =>
    r'8d105287f28cb5ebedb51e84951b129a4b6dfb6e';

abstract class _$ExternalFileEntryNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
