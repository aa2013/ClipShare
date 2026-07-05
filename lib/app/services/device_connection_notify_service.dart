import 'dart:async';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:get/get.dart';

/// 统一处理设备连接/断开的系统通知，避免不同传输协议重复实现防抖逻辑。
class DeviceConnectionNotifyService extends GetxService {
  final appConfig = Get.find<ConfigService>();

  // 正在防抖的设备通知，value 为 true 表示待发送断开通知，false 表示待发送连接通知。
  final _devNotifyIdMap = <String, bool>{};
  Timer? _devNotifyTimer;

  // 连接状态短时间抖动时只保留最终状态，避免连接/断开通知同时出现。
  static final _debounceTime = 1500.ms;

  /// 设备连接后发起通知。
  void showConnected(String devId, {required bool isPaired}) {
    if (!appConfig.notifyOnDevConn || !isPaired) {
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
      final devService = Get.find<DeviceService>();
      final notifyContent = TranslationKey.devConnectedNotifyContent.trParams({
        "devName": devService.getName(devId),
      });
      final key = "dev-conn-$devId";
      int? notifyId;
      if (!appConfig.useTrayFlashingForConnection) {
        await NotifyUtil.cancelAll(key);
        notifyId = await NotifyUtil.notify(
          key: key,
          content: notifyContent,
        );
      } else {
        final trayService = Get.find<TrayService>();
        trayService.flashTrayNormal(notifyContent);
      }
      if (notifyId != null) {
        Future.delayed(2.s, () {
          NotifyUtil.cancel(key, notifyId!);
        });
      }
    });
  }

  /// 设备断开后发起通知。
  void showDisconnected(String devId, {required bool isPaired}) {
    if (!appConfig.notifyOnDevDisconn || !isPaired) {
      return;
    }
    _devNotifyTimer?.cancel();
    _devNotifyIdMap[devId] = true;
    _devNotifyTimer = Timer(_debounceTime, () async {
      _devNotifyIdMap.remove(devId);
      final devService = Get.find<DeviceService>();
      final notifyContent = TranslationKey.devDisconnectNotifyContent.trParams({
        "devName": devService.getName(devId),
      });
      final key = "dev-disconn-$devId";
      int? notifyId;
      if (!appConfig.useTrayFlashingForConnection) {
        await NotifyUtil.cancelAll(key);
        notifyId = await NotifyUtil.notify(
          key: key,
          content: notifyContent,
        );
      } else {
        final trayService = Get.find<TrayService>();
        trayService.flashTrayWarning(notifyContent);
      }
      if (notifyId != null) {
        Future.delayed(2.s, () {
          NotifyUtil.cancel(key, notifyId!);
        });
      }
    });
  }
}
