// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 生成首页导航项统一数据源。
///
/// 依赖当前翻译对象后，首页、左侧导航和底部导航都会在语言切换完成后重新构建。

@ProviderFor(homeNavigationItems)
final homeNavigationItemsProvider = HomeNavigationItemsProvider._();

/// 生成首页导航项统一数据源。
///
/// 依赖当前翻译对象后，首页、左侧导航和底部导航都会在语言切换完成后重新构建。

final class HomeNavigationItemsProvider
    extends
        $FunctionalProvider<
          List<HomeNavigationItemData>,
          List<HomeNavigationItemData>,
          List<HomeNavigationItemData>
        >
    with $Provider<List<HomeNavigationItemData>> {
  /// 生成首页导航项统一数据源。
  ///
  /// 依赖当前翻译对象后，首页、左侧导航和底部导航都会在语言切换完成后重新构建。
  HomeNavigationItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeNavigationItemsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeNavigationItemsHash();

  @$internal
  @override
  $ProviderElement<List<HomeNavigationItemData>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<HomeNavigationItemData> create(Ref ref) {
    return homeNavigationItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HomeNavigationItemData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HomeNavigationItemData>>(value),
    );
  }
}

String _$homeNavigationItemsHash() =>
    r'a3dfc41296771383b57e5ef12ee97a80e09e05a4';
