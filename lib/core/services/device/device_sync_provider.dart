import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_sync_provider.g.dart';

/// 设备元数据同步处理器。
@Riverpod(keepAlive: true)
class DeviceSyncNotifier extends _$DeviceSyncNotifier {
  static const tag = 'DeviceSyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  String get _selfGuid => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo.guid;

  @override
  void build() {
    unawaited(_listenSyncEvents());
  }

  /// 监听设备同步事件，应用成功后回传确认。
  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        if (event is! DeviceSyncEvent) {
          continue;
        }
        if (!await _apply(event)) {
          continue;
        }
        _syncNotifier.emitPendingAckFor(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 应用设备增删改；本机设备信息由本机维护，不允许被远端覆盖。
  Future<bool> _apply(DeviceSyncEvent event) async {
    final device = event.device;
    if (device.guid.isEmpty || device.guid == _selfGuid) {
      //强制忽略事件，避免对端反复补推
      return true;
    }
    switch (event.method) {
      case .add:
      case .update:
        return _deviceNotifier.addOrUpdate(device);
      case .delete:
        final exists = await _deviceDao.getById(device.guid) != null;
        if (!exists) {
          // 已不存在视为删除成功，避免对端反复补推
          return true;
        }
        return _deviceNotifier.remove(device.guid);
      case .unknown:
        return false;
    }
  }
}
