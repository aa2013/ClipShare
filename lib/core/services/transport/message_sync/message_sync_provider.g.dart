// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessageSyncNotifier)
final messageSyncProvider = MessageSyncNotifierProvider._();

final class MessageSyncNotifierProvider
    extends $NotifierProvider<MessageSyncNotifier, void> {
  MessageSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageSyncNotifierHash();

  @$internal
  @override
  MessageSyncNotifier create() => MessageSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$messageSyncNotifierHash() =>
    r'b1ad3c89f8f044d3dfd8a99d5d4f5dadcf41f876';

abstract class _$MessageSyncNotifier extends $Notifier<void> {
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
