import 'dart:io';

import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class NotifyUtil {
  static var _notificationReady = false;
  static var _notifyId = 1;
  static final _notification = FlutterLocalNotificationsPlugin();
  static final Map<String, List<int>> _notifyIds = {};

  static Future<void> _initNotifications() async {
    if (_notificationReady) return;
    const iosSettings = DarwinInitializationSettings();
    var iconPath = File.fromUri(WindowsImage.getAssetUri(Constants.logoPngPath)).absolute.path;
    final windowsSettings = WindowsInitializationSettings(
      appName: Constants.appName,
      appUserModelId: Constants.pkgName,
      guid: Constants.appGuid,
      iconPath: iconPath,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');

    final settings = InitializationSettings(
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notification.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        windowManager.show();
      },
    );
    _notificationReady = true;
  }

  static Future<int?> notify({
    String title = Constants.appName,
    required String content,
    String? key,
    String? payload,
  }) async {
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      final notifyId = await androidChannelService.sendNotify(content);
      if (key == null || notifyId == null) return null;
      if (!_notifyIds.containsKey(key)) {
        List<int> ids = [notifyId];
        _notifyIds[key] = ids;
      } else {
        _notifyIds[key]!.add(notifyId);
      }
      return notifyId;
    }
    if (!_notificationReady) {
      await _initNotifications();
    }
    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    await _notification.show(
      _notifyId++,
      title,
      content,
      notificationDetails,
      payload: payload,
    );
    return null;
  }

  static void cancel(String key, int notifyId) {
    if (!Platform.isAndroid) return;
    if (!_notifyIds.containsKey(key)) {
      return;
    }
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.cancelNotify(notifyId);
    _notifyIds[key]!.remove(notifyId);
  }

  static cancelExcludeLast(String key) {
    if (!Platform.isAndroid) return;
    if (!_notifyIds.containsKey(key)) {
      return;
    }
    var ids = _notifyIds[key]!;
    if (ids.length <= 1) {
      return;
    }
    var last = ids.last;
    _notifyIds[key] = [last];
    ids = ids..removeLast();
    final androidChannelService = Get.find<AndroidChannelService>();
    for (var id in ids) {
      androidChannelService.cancelNotify(id);
    }
  }

  static cancelAll(String key) {
    if (!Platform.isAndroid) return;
    if (!_notifyIds.containsKey(key)) {
      return;
    }
    var ids = _notifyIds[key]!;
    final androidChannelService = Get.find<AndroidChannelService>();
    for (var id in ids) {
      androidChannelService.cancelNotify(id);
    }
    _notifyIds[key]!.clear();
  }
}
