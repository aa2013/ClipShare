// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_cleanup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据清理服务：级联删除、孤儿设备回收与自动清理定时器。
/// UI 反馈（弹窗、SnackBar）由调用方负责，本服务不依赖 BuildContext。

@ProviderFor(DataCleanupNotifier)
final dataCleanupProvider = DataCleanupNotifierProvider._();

/// 数据清理服务：级联删除、孤儿设备回收与自动清理定时器。
/// UI 反馈（弹窗、SnackBar）由调用方负责，本服务不依赖 BuildContext。
final class DataCleanupNotifierProvider
    extends $AsyncNotifierProvider<DataCleanupNotifier, void> {
  /// 数据清理服务：级联删除、孤儿设备回收与自动清理定时器。
  /// UI 反馈（弹窗、SnackBar）由调用方负责，本服务不依赖 BuildContext。
  DataCleanupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataCleanupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataCleanupNotifierHash();

  @$internal
  @override
  DataCleanupNotifier create() => DataCleanupNotifier();
}

String _$dataCleanupNotifierHash() =>
    r'a372b7c57d76b1070380d9c7b58b25483d5fcbb3';

/// 数据清理服务：级联删除、孤儿设备回收与自动清理定时器。
/// UI 反馈（弹窗、SnackBar）由调用方负责，本服务不依赖 BuildContext。

abstract class _$DataCleanupNotifier extends $AsyncNotifier<void> {
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
