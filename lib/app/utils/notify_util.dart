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
    required String key,
    Uri? windowsImageUri,
    String? payload,
  }) async {
    int? notifyId;
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      notifyId = await androidChannelService.sendNotify(content);
    } else {
      if (!_notificationReady) {
        await _initNotifications();
      }
      NotificationDetails notificationDetails = NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(
          images: [
            WindowsImage(
              windowsImageUri ?? WindowsImage.getAssetUri(Constants.logoPngPath),
              altText: '',
              placement: WindowsImagePlacement.appLogoOverride,
            ),
          ],
        ),
      );
      notifyId = _notifyId;
      _notifyId++;
      await _notification.show(
        notifyId,
        title,
        content,
        notificationDetails,
        payload: payload,
      );
    }
    if (notifyId == null) return null;
    if (!_notifyIds.containsKey(key)) {
      List<int> ids = [notifyId];
      _notifyIds[key] = ids;
    } else {
      _notifyIds[key]!.add(notifyId);
    }
    return notifyId;
  }

  static void cancel(String key, int notifyId) {
    if (!_notifyIds.containsKey(key)) {
      return;
    }
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      androidChannelService.cancelNotify(notifyId);
    } else {
      _notification.cancel(notifyId);
    }
    _notifyIds[key]!.remove(notifyId);
  }

  static cancelExcludeLast(String key) {
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
      if (Platform.isAndroid) {
        androidChannelService.cancelNotify(id);
      } else {
        _notification.cancel(id);
      }
    }
  }

  static cancelAll(String key) {
    if (!_notifyIds.containsKey(key)) {
      return;
    }
    var ids = _notifyIds[key]!;
    final androidChannelService = Get.find<AndroidChannelService>();
    for (var id in ids) {
      if (Platform.isAndroid) {
        androidChannelService.cancelNotify(id);
      } else {
        _notification.cancel(id);
      }
    }
    _notifyIds[key]!.clear();
  }
}
