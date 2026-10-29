// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_cleanup_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据清理页面状态与动作：负责过滤器编辑、配置保存与清理执行（含 UI 反馈）。

@ProviderFor(DataCleanupPageNotifier)
final dataCleanupPageProvider = DataCleanupPageNotifierProvider._();

/// 数据清理页面状态与动作：负责过滤器编辑、配置保存与清理执行（含 UI 反馈）。
final class DataCleanupPageNotifierProvider
    extends $NotifierProvider<DataCleanupPageNotifier, DataCleanupPageState> {
  /// 数据清理页面状态与动作：负责过滤器编辑、配置保存与清理执行（含 UI 反馈）。
  DataCleanupPageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataCleanupPageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataCleanupPageNotifierHash();

  @$internal
  @override
  DataCleanupPageNotifier create() => DataCleanupPageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataCleanupPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataCleanupPageState>(value),
    );
  }
}

String _$dataCleanupPageNotifierHash() =>
    r'422307a7128578f00e15b36fb63f2d80d106334f';

/// 数据清理页面状态与动作：负责过滤器编辑、配置保存与清理执行（含 UI 反馈）。

abstract class _$DataCleanupPageNotifier
    extends $Notifier<DataCleanupPageState> {
  DataCleanupPageState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DataCleanupPageState, DataCleanupPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataCleanupPageState, DataCleanupPageState>,
              DataCleanupPageState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
