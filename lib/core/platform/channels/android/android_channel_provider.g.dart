// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AndroidChannelNotifier)
final androidChannelProvider = AndroidChannelNotifierProvider._();

final class AndroidChannelNotifierProvider
    extends $NotifierProvider<AndroidChannelNotifier, void> {
  AndroidChannelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidChannelNotifierHash();

  @$internal
  @override
  AndroidChannelNotifier create() => AndroidChannelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$androidChannelNotifierHash() =>
    r'1e908aa4fdbf27c8556028e4643e712e1b85d1b6';

abstract class _$AndroidChannelNotifier extends $Notifier<void> {
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
