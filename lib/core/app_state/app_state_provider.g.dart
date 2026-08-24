// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 运行时配置

@ProviderFor(AppStateNotifier)
final appStateProvider = AppStateNotifierProvider._();

/// 运行时配置
final class AppStateNotifierProvider
    extends $NotifierProvider<AppStateNotifier, AppState> {
  /// 运行时配置
  AppStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStateNotifierHash();

  @$internal
  @override
  AppStateNotifier create() => AppStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppState>(value),
    );
  }
}

String _$appStateNotifierHash() => r'8844772eef8bff2d51e94725b5a3343e9626eb17';

/// 运行时配置

abstract class _$AppStateNotifier extends $Notifier<AppState> {
  AppState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppState, AppState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppState, AppState>,
              AppState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
