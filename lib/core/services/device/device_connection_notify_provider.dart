import 'dart:async';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_connection_notify_provider.g.dart';

@Riverpod(keepAlive: true)
class DeviceConnectionNotifyNotifier extends _$DeviceConnectionNotifyNotifier {
  // 正在防抖的设备通知，value 为 true 表示待发送断开通知，false 表示待发送连接通知。
  final _devNotifyIdMap = <String, bool>{};

  // 连接状态短时间抖动时只保留最终状态，避免连接/断开提示同时出现。
  Timer? _devNotifyTimer;

  static final _debounceTime = 1500.ms;

  StreamSubscription<DeviceLifecycleEvent>? _lifecycleSub;

  NotificationSettings get _notificationSettings => ref.read(notificationSettingsProvider).requireValue;

  PreferenceSettings get _preferenceSettings => ref.read(preferenceSettingsProvider).requireValue;

  NotifyNotifier get _notifyNotifier => ref.read(notifyProvider.notifier);

  DeviceState get _devState => ref.read(deviceProvider).requireValue;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  TrayNotifier get _trayNotifier => ref.read(trayProvider.notifier);

  @override
  void build() {
    _lifecycleSub = _deviceNotifier.lifecycleEvents.listen(_onLifecycleEvent);
    ref.onDispose(_dispose);
  }

  /// 释放事件订阅与防抖定时器。
  void _dispose() {
    _lifecycleSub?.cancel();
    _devNotifyTimer?.cancel();
    _devNotifyIdMap.clear();
  }

  /// 连接/断开统一由设备生命周期广播驱动，系统通知与托盘闪烁各自独立判断。
  void _onLifecycleEvent(DeviceLifecycleEvent event) {
    if (event is DeviceConnected) {
      _showConnected(event.device.guid);
    } else if (event is DeviceDisconnected) {
      _showDisconnected(
        event.deviceId,
        notifySystem: event.notify,
        manual: event.manual,
      );
    }
  }

  /// 设备连接后按开关发送系统通知和/或托盘闪烁。
  void _showConnected(String devId) {
    final isPaired = _isPaired(devId);
    final notifySystem = _notificationSettings.notifyOnDevConn;
    final useFlash = _preferenceSettings.useTrayFlashingForConnection && isDesktop;
    // 系统通知与托盘闪烁互相独立，两者都关闭才跳过
    if (!isPaired || (!notifySystem && !useFlash)) {
      return;
    }
    _schedule(devId, connected: true, dispatch: () async {
      final content = _connectedContent(devId);
      if (notifySystem) {
        await _notifyConnected(devId, content);
      }
      if (useFlash) {
        await _flashConnectedTray(content);
      }
    });
  }

  /// 设备断开后按开关发送系统通知和/或托盘闪烁。
  /// [notifySystem] 沿用原业务路径的系统通知判定，[manual] 为用户在设备页手动断开。
  void _showDisconnected(String devId, {required bool notifySystem, required bool manual}) {
    final isPaired = _isPaired(devId);
    // 手动断开只跳过托盘闪烁，系统通知仍按原条件处理
    final useFlash = _preferenceSettings.useTrayFlashingForConnection && isDesktop && !manual;
    if (!isPaired || (!notifySystem && !useFlash)) {
      return;
    }
    _schedule(devId, connected: false, dispatch: () async {
      final content = _disconnectedContent(devId);
      if (notifySystem) {
        await _notifyDisconnected(devId, content);
      }
      if (useFlash) {
        await _flashDisconnectedTray(content);
      }
    });
  }

  /// 连接/断开提示防抖：短时间内抖动时只保留最终状态。
  void _schedule(String devId, {required bool connected, required Future<void> Function() dispatch}) {
    _devNotifyTimer?.cancel();
    // 如果短时间内断开并重连，就同时取消提示。
    if (connected && _devNotifyIdMap[devId] == true) {
      _devNotifyIdMap.remove(devId);
      return;
    }
    _devNotifyIdMap[devId] = !connected;
    _devNotifyTimer = Timer(_debounceTime, () async {
      _devNotifyIdMap.remove(devId);
      await dispatch();
    });
  }

  /// 设备是否已配对；断开后已存储设备仍保留配对状态。
  bool _isPaired(String devId) => _devState.getStoredById(devId)?.isPaired ?? false;

  String _connectedContent(String devId) {
    return TranslationKey.devConnectedNotifyContent.trParams({
      'devName': _devState.getStoredName(devId) ?? unknownDeviceName,
    });
  }

  String _disconnectedContent(String devId) {
    return TranslationKey.devDisconnectNotifyContent.trParams({
      'devName': _devState.getStoredName(devId) ?? unknownDeviceName,
    });
  }

  /// 发送连接系统通知，短暂展示后自动取消。
  Future<void> _notifyConnected(String devId, String content) async {
    final key = 'dev-conn-$devId';
    _notifyNotifier.cancelAll(key);
    final notifyId = await _notifyNotifier.notify(
      key: key,
      content: content,
    );
    if (notifyId == null) {
      return;
    }
    Future.delayed(2.s, () {
      _notifyNotifier.cancel(key, notifyId);
    });
  }

  /// 发送断开系统通知，短暂展示后自动取消。
  Future<void> _notifyDisconnected(String devId, String content) async {
    final key = 'dev-disconn-$devId';
    _notifyNotifier.cancelAll(key);
    final notifyId = await _notifyNotifier.notify(
      key: key,
      content: content,
    );
    if (notifyId == null) {
      return;
    }
    Future.delayed(2.s, () {
      _notifyNotifier.cancel(key, notifyId);
    });
  }

  /// 以正常态图标闪烁托盘提示设备连接。
  Future<void> _flashConnectedTray(String content) => _trayNotifier.flashTrayNormal(content);

  /// 以警告态图标闪烁托盘提示设备断开。
  Future<void> _flashDisconnectedTray(String content) => _trayNotifier.flashTrayWarning(content);
}
