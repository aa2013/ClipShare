// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_external_file_receive_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AndroidExternalFileReceiveNotifier)
final androidExternalFileReceiveProvider =
    AndroidExternalFileReceiveNotifierProvider._();

final class AndroidExternalFileReceiveNotifierProvider
    extends $NotifierProvider<AndroidExternalFileReceiveNotifier, void> {
  AndroidExternalFileReceiveNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidExternalFileReceiveProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$androidExternalFileReceiveNotifierHash();

  @$internal
  @override
  AndroidExternalFileReceiveNotifier create() =>
      AndroidExternalFileReceiveNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$androidExternalFileReceiveNotifierHash() =>
    r'0f68f26158f424dd59672d5539dd81ea1c2603ec';

abstract class _$AndroidExternalFileReceiveNotifier extends $Notifier<void> {
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
