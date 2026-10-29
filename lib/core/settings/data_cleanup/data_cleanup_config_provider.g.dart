// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_cleanup_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 读取数据清理配置，未配置或格式非法时为 null。
/// 存储键沿用历史名 cleanDataConfig，保持老版本数据兼容。

@ProviderFor(DataCleanupConfigNotifier)
final dataCleanupConfigProvider = DataCleanupConfigNotifierProvider._();

/// 读取数据清理配置，未配置或格式非法时为 null。
/// 存储键沿用历史名 cleanDataConfig，保持老版本数据兼容。
final class DataCleanupConfigNotifierProvider
    extends
        $AsyncNotifierProvider<DataCleanupConfigNotifier, DataCleanupConfig?> {
  /// 读取数据清理配置，未配置或格式非法时为 null。
  /// 存储键沿用历史名 cleanDataConfig，保持老版本数据兼容。
  DataCleanupConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataCleanupConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataCleanupConfigNotifierHash();

  @$internal
  @override
  DataCleanupConfigNotifier create() => DataCleanupConfigNotifier();
}

String _$dataCleanupConfigNotifierHash() =>
    r'b4c3154e45a814a1a373bdf6c78904ee8e3868a9';

/// 读取数据清理配置，未配置或格式非法时为 null。
/// 存储键沿用历史名 cleanDataConfig，保持老版本数据兼容。

abstract class _$DataCleanupConfigNotifier
    extends $AsyncNotifier<DataCleanupConfig?> {
  FutureOr<DataCleanupConfig?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DataCleanupConfig?>, DataCleanupConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DataCleanupConfig?>, DataCleanupConfig?>,
              AsyncValue<DataCleanupConfig?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
