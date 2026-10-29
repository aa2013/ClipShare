// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_compose_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SendComposeNotifier)
final sendComposeProvider = SendComposeNotifierProvider._();

final class SendComposeNotifierProvider
    extends $NotifierProvider<SendComposeNotifier, SendComposeState> {
  SendComposeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendComposeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendComposeNotifierHash();

  @$internal
  @override
  SendComposeNotifier create() => SendComposeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendComposeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendComposeState>(value),
    );
  }
}

String _$sendComposeNotifierHash() =>
    r'f339de411e1093e19a2f7a0a8d984d7094ee45e7';

abstract class _$SendComposeNotifier extends $Notifier<SendComposeState> {
  SendComposeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SendComposeState, SendComposeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SendComposeState, SendComposeState>,
              SendComposeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
