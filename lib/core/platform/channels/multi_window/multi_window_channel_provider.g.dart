// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_window_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MultiWindowChannelNotifier)
final multiWindowChannelProvider = MultiWindowChannelNotifierProvider._();

final class MultiWindowChannelNotifierProvider
    extends $NotifierProvider<MultiWindowChannelNotifier, void> {
  MultiWindowChannelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiWindowChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiWindowChannelNotifierHash();

  @$internal
  @override
  MultiWindowChannelNotifier create() => MultiWindowChannelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$multiWindowChannelNotifierHash() =>
    r'c645ac8e4f191c28aa3c8fc26515590b2e6221ca';

abstract class _$MultiWindowChannelNotifier extends $Notifier<void> {
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
