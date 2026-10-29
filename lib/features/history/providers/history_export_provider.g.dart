// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_export_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 历史记录 Excel 导出服务：承载导出流程的进度上报、手动取消与并发保护。
///
/// 导出为跨页面长流程（可从历史页或移动端搜索页发起），
/// 因此使用 keepAlive 保证流程期间状态不被销毁。

@ProviderFor(HistoryExportNotifier)
final historyExportProvider = HistoryExportNotifierProvider._();

/// 历史记录 Excel 导出服务：承载导出流程的进度上报、手动取消与并发保护。
///
/// 导出为跨页面长流程（可从历史页或移动端搜索页发起），
/// 因此使用 keepAlive 保证流程期间状态不被销毁。
final class HistoryExportNotifierProvider
    extends $NotifierProvider<HistoryExportNotifier, void> {
  /// 历史记录 Excel 导出服务：承载导出流程的进度上报、手动取消与并发保护。
  ///
  /// 导出为跨页面长流程（可从历史页或移动端搜索页发起），
  /// 因此使用 keepAlive 保证流程期间状态不被销毁。
  HistoryExportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyExportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyExportNotifierHash();

  @$internal
  @override
  HistoryExportNotifier create() => HistoryExportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$historyExportNotifierHash() =>
    r'd469c37585bd96a17943af114231e2e903144eb1';

/// 历史记录 Excel 导出服务：承载导出流程的进度上报、手动取消与并发保护。
///
/// 导出为跨页面长流程（可从历史页或移动端搜索页发起），
/// 因此使用 keepAlive 保证流程期间状态不被销毁。

abstract class _$HistoryExportNotifier extends $Notifier<void> {
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
