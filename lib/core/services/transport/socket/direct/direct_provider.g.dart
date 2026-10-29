// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DirectNotifier)
final directProvider = DirectNotifierProvider._();

final class DirectNotifierProvider
    extends $NotifierProvider<DirectNotifier, void> {
  DirectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directNotifierHash();

  @$internal
  @override
  DirectNotifier create() => DirectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$directNotifierHash() => r'ef093c100efe8e59101f20a878274c741ef95166';

abstract class _$DirectNotifier extends $Notifier<void> {
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
