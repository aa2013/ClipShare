import 'dart:async';

import 'package:clipshare/core/platform/desktop/tray/tray_service.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_service_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
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
  Timer? _devNotifyTimer;

  // 连接状态短时间抖动时只保留最终状态，避免连接/断开通知同时出现。
  static final _debounceTime = 1500.ms;
  
  NotificationSettings get _notificationSettings => ref.read(notificationSettingsProvider).requireValue;

  PreferenceSettings get _preferenceSettings => ref.read(preferenceSettingsProvider).requireValue;

  NotifyNotifier get _notifyNotifier => ref.read(notifyProvider.notifier);

  DeviceState get _devState => ref.read(deviceProvider).requireValue;

  TrayService get _trayService => ref.read(trayServiceProvider).requireValue;


  @override
  void build() {

  }

  /// 设备连接后发起通知。
  void showConnected(String devId, {required bool isPaired}) {
    if (!_notificationSettings.notifyOnDevConn || !isPaired) {
      return;
    }
    _devNotifyTimer?.cancel();
    // 如果短时间内断开并重连，就同时取消通知。
    if (_devNotifyIdMap[devId] == true) {
      _devNotifyIdMap.remove(devId);
      return;
    }
    _devNotifyIdMap[devId] = false;
    _devNotifyTimer = Timer(_debounceTime, () async {
      _devNotifyIdMap.remove(devId);
      final notifyContent = TranslationKey.devConnectedNotifyContent.trParams({
        'devName': _devState.getName(devId),
      });
      final key = 'dev-conn-$devId';
      int? notifyId;
      if (!_preferenceSettings.useTrayFlashingForConnection) {
        _notifyNotifier.cancelAll(key);
        notifyId = await _notifyNotifier.notify(
          key: key,
          content: notifyContent,
        );
      } else {
        await _trayService.flashTrayNormal(notifyContent);
      }
      if (notifyId != null) {
        Future.delayed(2.s, () {
          _notifyNotifier.cancel(key, notifyId!);
        });
      }
    });
  }

  /// 设备断开后发起通知。
  void showDisconnected(String devId, {required bool isPaired}) {
    if (!_notificationSettings.notifyOnDevDisconn || !isPaired) {
      return;
    }
    _devNotifyTimer?.cancel();
    _devNotifyIdMap[devId] = true;
    _devNotifyTimer = Timer(_debounceTime, () async {
      _devNotifyIdMap.remove(devId);
      final notifyContent = TranslationKey.devDisconnectNotifyContent.trParams({
        'devName': _devState.getName(devId),
      });
      final key = 'dev-disconn-$devId';
      int? notifyId;
      if (!_preferenceSettings.useTrayFlashingForConnection) {
        _notifyNotifier.cancelAll(key);
        notifyId = await _notifyNotifier.notify(
          key: key,
          content: notifyContent,
        );
      } else {
        await _trayService.flashTrayWarning(notifyContent);
      }
      if (notifyId != null) {
        Future.delayed(2.s, () {
          _notifyNotifier.cancel(key, notifyId!);
        });
      }
    });
  }
}