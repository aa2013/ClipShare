// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page_index_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 首页当前页序，宽窄屏布局共用；供整窗拖拽等场景跨页跳转使用

@ProviderFor(HomePageIndexNotifier)
final homePageIndexProvider = HomePageIndexNotifierProvider._();

/// 首页当前页序，宽窄屏布局共用；供整窗拖拽等场景跨页跳转使用
final class HomePageIndexNotifierProvider
    extends $NotifierProvider<HomePageIndexNotifier, int> {
  /// 首页当前页序，宽窄屏布局共用；供整窗拖拽等场景跨页跳转使用
  HomePageIndexNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageIndexNotifierHash();

  @$internal
  @override
  HomePageIndexNotifier create() => HomePageIndexNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$homePageIndexNotifierHash() =>
    r'26ae0975b2c5110b019d36b5a864b1c3bf9b1f3d';

/// 首页当前页序，宽窄屏布局共用；供整窗拖拽等场景跨页跳转使用

abstract class _$HomePageIndexNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
