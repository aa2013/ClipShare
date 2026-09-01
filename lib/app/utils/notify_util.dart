import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/notification_payload_type.dart';
import 'package:clipshare/app/data/models/notification_payload.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class NotifyUtil {
  static const tag = 'NotifyUtil';
  static var _notificationReady = false;
  static var _notifyId = 1;
  static final _notification = FlutterLocalNotificationsPlugin();
  static final Map<String, List<int>> _notifyIds = {};
  /// Android 原生通知点击时通过 notifyId 回传，这里保存 id 与业务载荷的关联以统一分发。
  static final Map<int, NotificationPayload> _payloadById = {};
  static const _windowsFlutterAssetsDir = 'flutter_assets';
  static const _windowsFlutterDataDir = 'data';

  /// 初始化各平台通知插件，并在 Windows 上注册稳定的 Toast 应用身份与图标。
  static Future<void> _initNotifications() async {
    if (_notificationReady) return;
    const iosSettings = DarwinInitializationSettings();

    //region WindowsSettings
    final iconPath = _windowsNotificationIconPath(Constants.logoIcoPath);
    final windowsSettings = WindowsInitializationSettings(
      appName: Constants.appName,
      appUserModelId: _windowsAppUserModelId,
      guid: Constants.appGuid,
      iconPath: iconPath,
    );
    //endregion

    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    final settings = InitializationSettings(
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notification.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final raw = response.payload;
        NotificationPayload? payload;
        if (raw != null && raw.isNotEmpty) {
          try {
            payload = NotificationPayload.fromJsonString(raw);
          } catch (err, stack) {
            logger.error(tag, 'parse notification payload failed: $err', stack);
          }
        }
        await _onNotificationTap(payload);
      },
    );
    _notificationReady = true;
  }

  /// 通知点击后的统一业务分发入口。
  /// [payload] 为空表示普通通知（无可执行业务），仅做回退处理。
  /// Android 原生回调与 flutter_local_notifications 回调都汇入这里，便于后续迁移。
  static Future<void> _onNotificationTap(NotificationPayload? payload) async {
    if (payload != null) {
      if (await _handleNotificationPayload(payload)) {
        return;
      }
    }
    // 只有桌面端才需要拉起主窗口；移动端点击通知默认由系统带回前台。
    if (PlatformExt.isDesktop) {
      await windowManager.show();
    }
  }

  /// 处理 Android 原生通知点击回调，按 notifyId 查找到业务载荷后统一分发。
  static Future<void> handleNotifyClick(int notifyId) async {
    final payload = _payloadById.remove(notifyId);
    await _onNotificationTap(payload);
  }

  /// 统一处理通知点击后的业务分发，无法识别或处理失败时返回 false 交给上层回退处理。
  static Future<bool> _handleNotificationPayload(NotificationPayload payload) async {
    try {
      switch (payload.type) {
        case NotificationPayloadType.openFile:
          return await _openFileFromPayload(payload);
      }
    } catch (err, stack) {
      logger.error(tag, 'handle notification payload failed: $err', stack);
    }
    return false;
  }

  /// 从通知载荷里读取目标文件并打开，失败时返回 false 交给上层回退处理。
  static Future<bool> _openFileFromPayload(NotificationPayload payload) async {
    final filePath = payload.data[NotificationPayload.filePathKey]?.toString();
    if (filePath == null || filePath.isEmpty) {
      return false;
    }
    final file = File(filePath);
    if (!file.existsSync()) {
      logger.error(tag, 'notification target file not found: ${file.path}');
      return false;
    }
    final result = await OpenFile.open(file.normalizePath);
    if (result.type == ResultType.done) {
      return true;
    }
    logger.error(tag, 'open notification target file failed: ${result.message}');
    return false;
  }

  /// Windows Toast 使用 AUMID 作为应用身份，开发版独立注册以避免污染正式安装版图标。
  static String get _windowsAppUserModelId => kReleaseMode
      ? Constants.windowsAppUserModelId
      : Constants.windowsDevAppUserModelId;

  /// 解析 Windows AUMID 应用身份图标路径；该图标不是单条通知里的 appLogoOverride 图片。
  static String? _windowsNotificationIconPath(String assetPath) {
    if (!Platform.isWindows) {
      return null;
    }
    final iconUri = _windowsAssetUri(assetPath);
    if (!iconUri.isScheme('file')) {
      return null;
    }
    final iconFile = File.fromUri(iconUri).absolute;
    // 只注册真实存在的图标路径，避免 Windows Toast 长期缓存错误的 IconUri。
    return iconFile.existsSync() ? iconFile.path : null;
  }

  /// 发送系统通知，并按业务 key 记录通知 id 以便后续批量取消。
  static Future<int?> notify({
    String title = Constants.appName,
    required String content,
    required String key,
    Uri? notificationLogoUri,
    NotificationPayload? payload,
  }) async {
    int? notifyId;
    if(title.isEmpty){
      title = Constants.appName;
    }
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      notifyId = await androidChannelService.sendNotify(title, content);
      // Android 通知点击由原生通过 notifyId 回传，这里先保存载荷与 id 的关联以便统一分发。
      if (notifyId != null && payload != null) {
        _payloadById[notifyId] = payload;
      }
    } else {
      if (!_notificationReady) {
        await _initNotifications();
      }
      if(Platform.isIOS){
        if(!await PermissionHelper.checkIOSNotificationPermission()){
          if(!await PermissionHelper.reqIOSNotificationPermission()){
            Global.showTipsDialog(context: Get.context!, text: TranslationKey.noNotificationPermission.tr);
            return null;
          }
        }
      }
      final notificationDetails = NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(attachments: [
          if(notificationLogoUri != null)
            DarwinNotificationAttachment(File.fromUri(notificationLogoUri).path)
        ]),
        linux: const LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(
          images: [
            WindowsImage(
              notificationLogoUri ?? _windowsAssetUri(Constants.logoPngPath),
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
        payload: payload == null ? null : jsonEncode(payload.toJson()),
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

  /// 解析 Windows Toast 可读取的 Flutter asset URI，release exe 版必须基于程序目录而不是当前工作目录。
  static Uri _windowsAssetUri(String assetPath) {
    if (!Platform.isWindows || kDebugMode || MsixUtils.hasPackageIdentity()) {
      return WindowsImage.getAssetUri(assetPath);
    }
    final assetFilePath = [
      File(Platform.resolvedExecutable).parent.path,
      _windowsFlutterDataDir,
      _windowsFlutterAssetsDir,
      assetPath.replaceAll('/', Platform.pathSeparator),
    ].join(Platform.pathSeparator);
    return Uri.file(assetFilePath, windows: true);
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
    _payloadById.remove(notifyId);
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
      _payloadById.remove(id);
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
      _payloadById.remove(id);
    }
    _notifyIds[key]!.clear();
  }
}
