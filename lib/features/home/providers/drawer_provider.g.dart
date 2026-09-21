// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DrawerNotifier)
final drawerProvider = DrawerNotifierProvider._();

final class DrawerNotifierProvider
    extends $NotifierProvider<DrawerNotifier, DrawerState> {
  DrawerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'drawerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$drawerNotifierHash();

  @$internal
  @override
  DrawerNotifier create() => DrawerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DrawerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DrawerState>(value),
    );
  }
}

String _$drawerNotifierHash() => r'e76df0eb213f0c49f773a3b36a74adc5486aa9a2';

abstract class _$DrawerNotifier extends $Notifier<DrawerState> {
  DrawerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DrawerState, DrawerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DrawerState, DrawerState>,
              DrawerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
