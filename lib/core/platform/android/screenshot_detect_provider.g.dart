// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_detect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScreenshotDetectNotifier)
final screenshotDetectProvider = ScreenshotDetectNotifierProvider._();

final class ScreenshotDetectNotifierProvider
    extends $NotifierProvider<ScreenshotDetectNotifier, void> {
  ScreenshotDetectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotDetectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotDetectNotifierHash();

  @$internal
  @override
  ScreenshotDetectNotifier create() => ScreenshotDetectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$screenshotDetectNotifierHash() =>
    r'd3094c69153a9d82574041c2dc2097bd77a788c4';

abstract class _$ScreenshotDetectNotifier extends $Notifier<void> {
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
