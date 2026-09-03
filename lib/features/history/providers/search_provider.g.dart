// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 历史搜索状态源：页面负责把它接入受控过滤器组件与列表。

@ProviderFor(SearchNotifier)
final searchProvider = SearchNotifierProvider._();

/// 历史搜索状态源：页面负责把它接入受控过滤器组件与列表。
final class SearchNotifierProvider
    extends $NotifierProvider<SearchNotifier, SearchState> {
  /// 历史搜索状态源：页面负责把它接入受控过滤器组件与列表。
  SearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchNotifierHash();

  @$internal
  @override
  SearchNotifier create() => SearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }
}

String _$searchNotifierHash() => r'29108cd822dc1c3115555975fe19db52529010bd';

/// 历史搜索状态源：页面负责把它接入受控过滤器组件与列表。

abstract class _$SearchNotifier extends $Notifier<SearchState> {
  SearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
