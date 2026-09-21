// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClipChannelNotifier)
final clipChannelProvider = ClipChannelNotifierProvider._();

final class ClipChannelNotifierProvider
    extends $NotifierProvider<ClipChannelNotifier, void> {
  ClipChannelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipChannelNotifierHash();

  @$internal
  @override
  ClipChannelNotifier create() => ClipChannelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$clipChannelNotifierHash() =>
    r'91d68cd14686184fa611b32f2d7f6f85d0565a9a';

abstract class _$ClipChannelNotifier extends $Notifier<void> {
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
