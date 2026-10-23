// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
///应用更新检查

@ProviderFor(AppUpdateInfoNotifier)
final appUpdateInfoProvider = AppUpdateInfoNotifierProvider._();

///应用更新检查
final class AppUpdateInfoNotifierProvider
    extends $AsyncNotifierProvider<AppUpdateInfoNotifier, void> {
  ///应用更新检查
  AppUpdateInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateInfoNotifierHash();

  @$internal
  @override
  AppUpdateInfoNotifier create() => AppUpdateInfoNotifier();
}

String _$appUpdateInfoNotifierHash() =>
    r'69684f7af7d5c35e8a922c06164de8fac86c6dc0';

///应用更新检查

abstract class _$AppUpdateInfoNotifier extends $AsyncNotifier<void> {
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
