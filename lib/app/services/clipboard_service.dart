import 'dart:io';
import 'dart:math';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipboard_listener/models/clipboard_source.dart';
import 'package:clipboard_listener/models/notification_content_config.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter_screenshot_detect/flutter_screenshot_detect.dart';
import 'package:get/get.dart';

class ClipboardService extends GetxService with ClipboardListener {
  final tag = "ClipboardService";
  final appConfig = Get.find<ConfigService>();
  final settingsController = Get.find<SettingsController>();
  var _detector = FlutterScreenshotDetect();

  static NotificationContentConfig get defaultNotificationContentConfig => NotificationContentConfig(
        errorTitle: TranslationKey.defaultClipboardServerNotificationCfgErrorTitle.tr,
        errorTextPrefix: TranslationKey.defaultClipboardServerNotificationCfgErrorTextPrefix.tr,
        stopListeningTitle: TranslationKey.defaultClipboardServerNotificationCfgStopListeningTitle.tr,
        stopListeningText: TranslationKey.defaultClipboardServerNotificationCfgStopListeningText.tr,
        serviceRunningTitle: TranslationKey.defaultClipboardServerNotificationCfgRunningTitle.tr,
        shizukuRunningText: TranslationKey.defaultClipboardServerNotificationCfgShizukuRunningText.tr,
        rootRunningText: TranslationKey.defaultClipboardServerNotificationCfgRootRunningText.tr,
        shizukuDisconnectedTitle: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedTitle.tr,
        shizukuDisconnectedText: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedText.tr,
        waitingRunningTitle: TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningTitle.tr,
        waitingRunningText: TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningText.tr,
      );
  String? _lastScreenshotContent;

  Future<ClipboardService> init() async {
    clipboardManager.addListener(this);
    if (appConfig.autoCopyImageAfterScreenShot) {
      startListenScreenshot();
    }
    if (Platform.isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(execDir)) {
        clipboardManager.setTempFileDir(await Constants.documentsPath);
      }
    }
    return this;
  }

  void startListenScreenshot() {
    if (!Platform.isAndroid) return;
    stopListenScreenshot();
    _detector = FlutterScreenshotDetect();
    _detector.startListening((event) {
      if (event.path != null && _lastScreenshotContent != event.path) {
        _lastScreenshotContent = event.path;
        final androidChannelService = Get.find<AndroidChannelService>();
        Future.delayed(const Duration(milliseconds: 500), () {
          androidChannelService.getImageUriRealPath(event.path!).then((realPath) async {
            Log.debug(tag, "content uri: ${event.path!}");
            Log.debug(tag, "realPath: $realPath");
            realPath = realPath?.toLowerCase();
            bool checkLatestImage = false;
            if (realPath == null) {
              Log.debug(
                tag,
                "real path is null, attempt to get latest image path",
              );
              try {
                checkLatestImage = true;
                final latestImagePath = await androidChannelService.getLatestImagePath();
                if (latestImagePath == null) {
                  Log.warn(tag, "latest image path is null");
                  return;
                }
                Log.debug(tag, "latest image path is $latestImagePath");
                realPath = latestImagePath;
              } catch (e) {
                return;
              }
            }
            final file = File(realPath);
            final lastModified = file.lastModifiedSync();
            final now = DateTime.now();
            final diffMs = now.difference(lastModified).inMilliseconds;
            Log.debug(
              tag,
              "file lastModifiedTime $lastModified. diff: $diffMs ms",
            );
            if (diffMs > 3000 && checkLatestImage) {
              //最新图片的修改时间与当前时间差距超过3s，忽略
              Log.debug(tag, "$diffMs ms More than 3 seconds.");
              return;
            }
            bool isScreenShot = false;
            for (var screenshotKey in Constants.screenshotKeywords) {
              screenshotKey = screenshotKey.toLowerCase();
              if (realPath.contains(screenshotKey)) {
                isScreenShot = true;
                break;
              }
            }
            if (!isScreenShot) {
              return;
            }
            androidChannelService.copyFileFromUri(event.path!, appConfig.cachePath).then((res) {
              Log.debug(tag, "ScreenshotDetect: $realPath");
              if (res != null) {
                HistoryDataListener.inst.onChanged(HistoryContentType.image, res, null);
              }
            });
          });
        });
      }
    });
  }

  void stopListenScreenshot() {
    _detector.dispose();
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content, ClipboardSource? source) {
    final contentType = HistoryContentType.parse(type.name);
    Log.debug(tag, "onChange ${content.substring(0, min(content.length, 200))}");
    HistoryDataListener.inst.onChanged(contentType, content, source);
  }

  @override
  Future<void> onPermissionStatusChanged(EnvironmentType environment, bool isGranted) async {
    if (appConfig.selectingWorkingMode.value) {
      return;
    }
    final settingsController = Get.find<SettingsController>();
    if (isGranted && environment != EnvironmentType.none && environment != EnvironmentType.androidPre10) {
      await clipboardManager.startListening(
        env: environment,
        way: appConfig.clipboardListeningWay,
        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
      );
    }
    settingsController.checkAndroidEnvPermission();
  }

  @override
  void onClose() {
    clipboardManager.removeListener(this);
    _detector.dispose();
    super.onClose();
  }
}
