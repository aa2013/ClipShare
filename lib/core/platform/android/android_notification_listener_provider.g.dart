// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_notification_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AndroidNotificationListenerNotifier)
final androidNotificationListenerProvider =
    AndroidNotificationListenerNotifierProvider._();

final class AndroidNotificationListenerNotifierProvider
    extends $NotifierProvider<AndroidNotificationListenerNotifier, void> {
  AndroidNotificationListenerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidNotificationListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$androidNotificationListenerNotifierHash();

  @$internal
  @override
  AndroidNotificationListenerNotifier create() =>
      AndroidNotificationListenerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$androidNotificationListenerNotifierHash() =>
    r'0047149e5786817d811e30f3b19cfc874e9ce988';

abstract class _$AndroidNotificationListenerNotifier extends $Notifier<void> {
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
