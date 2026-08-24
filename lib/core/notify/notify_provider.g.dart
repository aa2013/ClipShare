// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotifyNotifier)
final notifyProvider = NotifyNotifierProvider._();

final class NotifyNotifierProvider
    extends $AsyncNotifierProvider<NotifyNotifier, void> {
  NotifyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notifyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notifyNotifierHash();

  @$internal
  @override
  NotifyNotifier create() => NotifyNotifier();
}

String _$notifyNotifierHash() => r'85e47cffc0494e32f6a456336c1ab40d192cfc6f';

abstract class _$NotifyNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
