// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_data_sync_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
///缺失数据补数进度服务：按设备记录批次进度，展示时聚合。
///完成条目冻结不移除，待全部设备完成后整表清除，保证聚合值单调不回退；
///中断（断连/超时）时才回落。订阅补数信封事件流，处理者无需感知本服务的存在。

@ProviderFor(MissingDataSyncProgress)
final missingDataSyncProgressProvider = MissingDataSyncProgressProvider._();

///缺失数据补数进度服务：按设备记录批次进度，展示时聚合。
///完成条目冻结不移除，待全部设备完成后整表清除，保证聚合值单调不回退；
///中断（断连/超时）时才回落。订阅补数信封事件流，处理者无需感知本服务的存在。
final class MissingDataSyncProgressProvider
    extends
        $NotifierProvider<
          MissingDataSyncProgress,
          MissingDataSyncProgressState
        > {
  ///缺失数据补数进度服务：按设备记录批次进度，展示时聚合。
  ///完成条目冻结不移除，待全部设备完成后整表清除，保证聚合值单调不回退；
  ///中断（断连/超时）时才回落。订阅补数信封事件流，处理者无需感知本服务的存在。
  MissingDataSyncProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missingDataSyncProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missingDataSyncProgressHash();

  @$internal
  @override
  MissingDataSyncProgress create() => MissingDataSyncProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissingDataSyncProgressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissingDataSyncProgressState>(value),
    );
  }
}

String _$missingDataSyncProgressHash() =>
    r'5e92289208c6197e8b83d5f5aa9c94003cd4265c';

///缺失数据补数进度服务：按设备记录批次进度，展示时聚合。
///完成条目冻结不移除，待全部设备完成后整表清除，保证聚合值单调不回退；
///中断（断连/超时）时才回落。订阅补数信封事件流，处理者无需感知本服务的存在。

abstract class _$MissingDataSyncProgress
    extends $Notifier<MissingDataSyncProgressState> {
  MissingDataSyncProgressState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<MissingDataSyncProgressState, MissingDataSyncProgressState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                MissingDataSyncProgressState,
                MissingDataSyncProgressState
              >,
              MissingDataSyncProgressState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
