import 'dart:async';

import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'missing_data_sync_progress_provider.g.dart';

///单设备补数进度
class MissingDataSyncProgressEntry {
  ///批次内序号（从 1 开始）
  final int seq;

  ///总数
  final int total;

  const MissingDataSyncProgressEntry({
    required this.seq,
    required this.total,
  });

  ///是否已完成
  bool get completed => seq >= total;
}

///补数进度快照，UI 侧聚合展示
class MissingDataSyncProgressState {
  ///设备 id -> 进度
  final Map<String, MissingDataSyncProgressEntry> entries;

  const MissingDataSyncProgressState({this.entries = const {}});

  ///聚合：所有设备 seq 之和
  int get sumSeq => entries.values.fold(0, (prev, item) => prev + item.seq);

  ///聚合：所有设备 total 之和
  int get sumTotal => entries.values.fold(0, (prev, item) => prev + item.total);

  ///是否存在进行中的补数
  bool get syncing => entries.isNotEmpty;
}

///缺失数据补数进度服务：按设备记录批次进度，展示时聚合
///完成条目冻结不移除，待全部设备完成后整表清除
///处理者无需感知本服务的存在。
///数据可能高频到达，按固定间隔防抖更新状态，避免 UI 过频重建。
@Riverpod(keepAlive: true)
class MissingDataSyncProgress extends _$MissingDataSyncProgress {
  static const tag = 'MissingDataSyncProgress';

  ///进度中断兜底时长：距最后一条补数超过该时长仍未完成视为中断
  static const _staleTimeout = Duration(seconds: 10);

  ///state 推送节流间隔
  static const _stateSyncInterval = Duration(milliseconds: 200);

  ///真实进度记录，state 为其节流快照
  final _entries = <String, MissingDataSyncProgressEntry>{};

  Timer? _staleTimer;
  Timer? _syncTimer;
  var _syncScheduled = false;
  StreamSubscription<MissingDataBatchEvent>? _batchSub;
  StreamSubscription<DeviceLifecycleEvent>? _lifecycleSub;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  @override
  MissingDataSyncProgressState build() {
    final syncNotifier = ref.read(messageSyncProvider.notifier);
    _batchSub = syncNotifier.missingDataBatchEvents.listen(_onBatchEvent);
    _lifecycleSub = _deviceNotifier.lifecycleEvents.listen(_onLifecycleEvent);
    ref.onDispose(_dispose);
    return const MissingDataSyncProgressState();
  }

  void _dispose() {
    _batchSub?.cancel();
    _lifecycleSub?.cancel();
    _staleTimer?.cancel();
    _syncTimer?.cancel();
  }

  ///收到一条补数消息信封，直接以信封的 seq/total 覆盖对应设备进度；
  ///新设备或新批次（seq==1）时自然完成重置
  void _onBatchEvent(MissingDataBatchEvent event) {
    if (event.total <= 1) {
      //单条补推不算批量，不进进度
      return;
    }
    _entries[event.devId] = MissingDataSyncProgressEntry(
      seq: event.seq,
      total: event.total,
    );
    //重置中断兜底：距最后一条补数超过阈值仍未完成则清空
    _staleTimer?.cancel();
    _staleTimer = Timer(_staleTimeout, _onStale);
    _scheduleStateSync();
  }

  ///设备断连移除其进度；其余设备恰好全部完成则整表清除
  void _onLifecycleEvent(DeviceLifecycleEvent event) {
    if (event is! DeviceDisconnected) {
      return;
    }
    if (_entries.remove(event.deviceId) == null) {
      return;
    }
    _scheduleStateSync();
  }

  ///防抖同步更新
  void _scheduleStateSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    _syncTimer = Timer(_stateSyncInterval, () {
      _syncScheduled = false;
      _updateState(Map.of(_entries));
    });
  }

  ///条目全部完成后清空整表，保证聚合值走满后整体消失
  void _updateState(Map<String, MissingDataSyncProgressEntry> entries) {
    final allCompleted = entries.values.every((item) => item.completed);
    state = MissingDataSyncProgressState(
      entries: allCompleted ? const {} : entries,
    );
  }

  ///进度中断兜底：距最后一条补数超过阈值仍未完成则清空
  void _onStale() {
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    _updateState(const {});
  }
}
