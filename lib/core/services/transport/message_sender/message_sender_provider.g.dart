// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_sender_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessageSenderNotifier)
final messageSenderProvider = MessageSenderNotifierProvider._();

final class MessageSenderNotifierProvider
    extends $NotifierProvider<MessageSenderNotifier, void> {
  MessageSenderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageSenderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageSenderNotifierHash();

  @$internal
  @override
  MessageSenderNotifier create() => MessageSenderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$messageSenderNotifierHash() =>
    r'd75335babbb8aefea798c1d52070d54aa14de7a4';

abstract class _$MessageSenderNotifier extends $Notifier<void> {
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
