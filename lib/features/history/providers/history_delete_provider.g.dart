// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_delete_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 历史记录删除服务：级联删除记录、同步删除操作并可选清理本地文件。
/// 供历史列表与文件传输页的历史记录列表共用。

@ProviderFor(HistoryDeleteNotifier)
final historyDeleteProvider = HistoryDeleteNotifierProvider._();

/// 历史记录删除服务：级联删除记录、同步删除操作并可选清理本地文件。
/// 供历史列表与文件传输页的历史记录列表共用。
final class HistoryDeleteNotifierProvider
    extends $NotifierProvider<HistoryDeleteNotifier, void> {
  /// 历史记录删除服务：级联删除记录、同步删除操作并可选清理本地文件。
  /// 供历史列表与文件传输页的历史记录列表共用。
  HistoryDeleteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyDeleteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyDeleteNotifierHash();

  @$internal
  @override
  HistoryDeleteNotifier create() => HistoryDeleteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$historyDeleteNotifierHash() =>
    r'11f29619eaed96cf40ffbe8cf12f554f9e6be4bc';

/// 历史记录删除服务：级联删除记录、同步删除操作并可选清理本地文件。
/// 供历史列表与文件传输页的历史记录列表共用。

abstract class _$HistoryDeleteNotifier extends $Notifier<void> {
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
