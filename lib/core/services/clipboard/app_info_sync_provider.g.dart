// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App 来源信息同步处理器。

@ProviderFor(AppInfoSyncNotifier)
final appInfoSyncProvider = AppInfoSyncNotifierProvider._();

/// App 来源信息同步处理器。
final class AppInfoSyncNotifierProvider
    extends $NotifierProvider<AppInfoSyncNotifier, void> {
  /// App 来源信息同步处理器。
  AppInfoSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoSyncNotifierHash();

  @$internal
  @override
  AppInfoSyncNotifier create() => AppInfoSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appInfoSyncNotifierHash() =>
    r'0677ad083e4dcc723ff05a677e21a328f8424b8b';

/// App 来源信息同步处理器。

abstract class _$AppInfoSyncNotifier extends $Notifier<void> {
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
