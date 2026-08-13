import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:clipshare_clipboard_listener/models/notification_content_config.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:desktop_click_outside/desktop_click_outside.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:flutter_screenshot_detect/flutter_screenshot_detect.dart';
import 'package:get/get.dart';
import 'package:uri_file_reader/uri_file_reader.dart';
import 'package:path/path.dart' as p;

class ClipboardService extends GetxService with ClipboardListener {
  final tag = "ClipboardService";
  final appConfig = Get.find<ConfigService>();
  final settingsController = Get.find<SettingsController>();
  var _detector = FlutterScreenshotDetect();
  final _isExcludeFormat = true.obs;
  var _pausedScreenshot = false;
  bool _recoveringShizukuBinderPermission = false;
  bool _requestingShizukuFromBinder = false;
  bool _showingShizukuRequestFailedDialog = false;
  DateTime? _lastShizukuDisconnectedNotifyAt;
  static const _shizukuDisconnectedNotifyKey = "shizukuDisconnected";
  static const _shizukuDisconnectedNotifyMinInterval = Duration(seconds: 10);

  bool get isExcludeFormat => _isExcludeFormat.value;

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
  StreamSubscription<void>? _clickOutsideSubscription;

  Future<ClipboardService> init() async {
    clipboardManager.addListener(this);
    if (PlatformExt.isDesktop) {
      // 点击外部事件
      _clickOutsideSubscription = DesktopClickOutside.instance.onClickOutside.listen((_) {
        _closeHistoryPopupIfNeeded();
      });
    }
    if (appConfig.autoCopyImageAfterScreenShot) {
      startListenScreenshot();
    }
    if (Platform.isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(execDir)) {
        clipboardManager.setTempFileDir(appConfig.documentsPath);
      }
      await clipboardManager.setExcludeFormatEnabled(appConfig.isExcludeFormat);
      _isExcludeFormat.value = await clipboardManager.isEnableExcludeFormat();
    }
    return this;
  }

  void startListenScreenshot() {
    if (!Platform.isAndroid) return;
    if (!appConfig.autoCopyImageAfterScreenShot) {
      return;
    }
    stopListenScreenshot();
    _detector = FlutterScreenshotDetect();
    _detector.startListening((event) async {
      if (event.path == null || _lastScreenshotContent == event.path) {
        return;
      }
      _lastScreenshotContent = event.path;
      try {
        await _detectScreenShotFile(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    });
  }

  Future<void> _detectScreenShotFile(FlutterScreenshotEvent event) async {
    final androidChannelService = Get.find<AndroidChannelService>();
    await Future.delayed(500.ms);
    final uriFileInfo = await uriFileReader.getFileInfoFromUri(event.path!);
    logger.debug(tag, "content uri: ${event.path!}");
    var realPath = uriFileInfo?.path;
    logger.debug(tag, "realPath: $realPath");
    bool checkLatestImage = false;
    if (realPath == null) {
      logger.debug(
        tag,
        "real path is null, attempt to get latest image path",
      );
      try {
        checkLatestImage = true;
        final latestImagePath = await androidChannelService.getLatestImagePath();
        if (latestImagePath == null) {
          logger.warn(tag, "latest image path is null");
          return;
        }
        logger.debug(tag, "latest image path is $latestImagePath");
        realPath = latestImagePath;
      } catch (e) {
        return;
      }
    }
    final screenshotFile = File(realPath);
    final lastModified = screenshotFile.lastModifiedSync();
    final now = DateTime.now();
    final diffMs = now.difference(lastModified).inMilliseconds;
    logger.debug(
      tag,
      "file lastModifiedTime $lastModified. diff: $diffMs ms",
    );
    if (diffMs > 3000 && checkLatestImage) {
      //最新图片的修改时间与当前时间差距超过3s，忽略
      logger.debug(tag, "$diffMs ms More than 3 seconds.");
      return;
    }
    bool isScreenShot = false;
    for (var screenshotKey in Constants.screenshotKeywords) {
      screenshotKey = screenshotKey.toLowerCase();
      if (realPath.toLowerCase().contains(screenshotKey)) {
        isScreenShot = true;
        break;
      }
    }
    if (!isScreenShot) {
      return;
    }
    var copySuccess = false;
    try {
      final newFilePath = await uriFileReader.copyFileFromUri(event.path!, appConfig.cachePath);
      logger.debug(tag, "ScreenshotDetect: $realPath");
      if (newFilePath != null) {
        HistoryDataListener.inst.onChanged(HistoryContentType.image, newFilePath, null);
        copySuccess = true;
      } else {
        logger.warn(tag, "Copy screenshot file failed!");
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    if (copySuccess) {
      return;
    }
    //尝试复制源文件
    var newPath = "${appConfig.cachePath}/${appConfig.snowflake.nextIdStr()}.jpg";
    final result = await clipboardManager.executePrivilegedCommand("cp ${screenshotFile.absolute.path} $newPath && echo 0");
    if (result == "0") {
      HistoryDataListener.inst.onChanged(HistoryContentType.image, newPath, null);
      logger.debug(tag, "attempt copy origin file via command success");
    } else {
      logger.debug(tag, "attempt copy origin file via command failed: $result");
      //源文件复制失败，判断是否是pending文件
      if (screenshotFile.fileName.startsWith(".pending-")) {
        final newFileName = screenshotFile.fileName.split("-").sublist(2).join('-');
        final path = p.join(screenshotFile.parent.absolute.path, newFileName);
        logger.debug(tag, "newPath = $path");
        var retryCnt = 0;
        while (retryCnt < 5) {
          logger.debug(tag, "retry ${retryCnt + 1} times..");
          final originFile = File(path);
          final exists = await originFile.exists();

          //尝试直接判断保存的文件是否存在
          if (exists) {
            try {
              var attempts = 0;
              List<int> bytes = [];
              const maxAttempts = 2;
              while (attempts++ < maxAttempts && (bytes = await originFile.readAsBytes()).isEmpty) {
                if (attempts < maxAttempts) {
                  await Future.delayed(1000.ms);
                }
              }
              if (bytes.isNotEmpty) {
                await File(newPath).writeAsBytes(bytes);
                HistoryDataListener.inst.onChanged(HistoryContentType.image, newPath, null);
                break;
              }
            } catch (err, stack) {
              logger.error(tag, "copy screenshot failed: $err", stack);
            }
          }

          //尝试提权复制
          final result = await clipboardManager.executePrivilegedCommand("cp $path $newPath && echo 0");
          if (result == "0") {
            logger.debug(tag, "attempt copy file via command success");
            HistoryDataListener.inst.onChanged(HistoryContentType.image, newPath, null);
            break;
          } else {
            logger.debug(tag, "attempt copy file via command failed: $result");
          }
          await Future.delayed(2.s);
          retryCnt++;
        }
      }
    }
  }

  void stopListenScreenshot() {
    _detector.dispose();
  }

  Future<void> setExcludeFormat(bool enabled) async {
    if (!Platform.isWindows) {
      return;
    }
    await clipboardManager.setExcludeFormatEnabled(enabled);
    _isExcludeFormat.value = enabled;
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content, ClipboardSource? source) {
    final contentType = HistoryContentType.parse(type.name);
    logger.debug(tag, "onChange ${content.substring(0, min(content.length, 200))}");
    HistoryDataListener.inst.onChanged(contentType, content, source);
  }

  @override
  void onForegroundChanged(bool isSelf) {
    if (isSelf) {
      return;
    }
    _closeHistoryPopupIfNeeded();
  }

  ///按桌面端点击外部规则决定是否关闭历史弹窗。
  void _closeHistoryPopupIfNeeded() {
    if (!PlatformExt.isDesktop) {
      return;
    }
    if (!appConfig.autoClosePopupOnBlur) {
      return;
    }
    // 置顶弹窗保持打开，直到用户显式关闭。
    if (appConfig.historyPinned.value) {
      return;
    }
    final historyWindow = appConfig.historyWindow;
    if (historyWindow == null) {
      return;
    }
    final multiWindowService = Get.find<MultiWindowChannelService>();
    if (multiWindowService.isHideWindow(historyWindow.windowId)) {
      return;
    }
    multiWindowService
        .hideChildWindow(historyWindow.windowId, MultiWindowTag.history)
        .catchError((err) {
      logger.warn(tag, "hideChildWindow failed: $err");
    });
  }

  @override
  Future<void> onPermissionStatusChanged(EnvironmentType environment, bool isGranted) async {
    if (appConfig.selectingWorkingMode.value) {
      return;
    }
    if (environment == EnvironmentType.shizuku && !isGranted) {
      final shouldShowRequestFailedDialog = _requestingShizukuFromBinder;
      _requestingShizukuFromBinder = false;
      _recoveringShizukuBinderPermission = false;
      // Shizuku 权限请求失败时只做轻量标记，避免立刻访问可能刚断开的远端状态。
      settingsController.markShizukuUnavailable();
      if (shouldShowRequestFailedDialog) {
        _showShizukuRequestFailedDialog();
      }
      return;
    }
    if (isGranted && environment != EnvironmentType.none && environment != EnvironmentType.androidPre10) {
      await _startListeningWithEnvironment(environment);
    }
    if (environment == EnvironmentType.shizuku) {
      if (isGranted) {
        _requestingShizukuFromBinder = false;
      }
    }
    settingsController.checkAndroidEnvPermission();
  }

  @override
  Future<void> onShizukuBinderStatusChanged(bool available) async {
    if (!Platform.isAndroid) return;
    if (!available) {
      _requestingShizukuFromBinder = false;
      _recoveringShizukuBinderPermission = false;
      // Shizuku 服务断开时只标记界面状态，不主动查询或请求权限，避免触发失效 binder。
      settingsController.markShizukuUnavailable();
      return;
    }
    await _recoverShizukuAfterBinderAvailable();
  }

  /// Shizuku binder 可用后恢复授权和监听状态。
  ///
  /// binder 可用只代表 Shizuku 服务可连接；这里仍需先检查应用是否已授权，
  /// 未授权时才触发 Shizuku 权限请求。
  Future<void> _recoverShizukuAfterBinderAvailable() async {
    if (_recoveringShizukuBinderPermission || _requestingShizukuFromBinder) return;
    if (appConfig.workingMode != EnvironmentType.shizuku || appConfig.ignoreShizuku || appConfig.selectingWorkingMode.value) {
      return;
    }
    _recoveringShizukuBinderPermission = true;
    try {
      final hasPermission = await clipboardManager.checkPermission(EnvironmentType.shizuku);
      if (hasPermission) {
        await _startListeningWithEnvironment(EnvironmentType.shizuku);
        settingsController.checkAndroidEnvPermission();
        return;
      }
      _requestingShizukuFromBinder = true;
      await clipboardManager.requestPermission(EnvironmentType.shizuku);
    } catch (err, stack) {
      logger.error(tag, err, stack);
      _requestingShizukuFromBinder = false;
      _showShizukuRequestFailedDialog();
      // 自动恢复期间异常通常代表 Shizuku 状态刚变化，避免立刻再次访问插件 API。
      settingsController.markShizukuUnavailable();
    } finally {
      _recoveringShizukuBinderPermission = false;
    }
  }

  /// 使用指定工作环境启动剪贴板监听。
  ///
  /// Shizuku binder 重连和权限请求成功都会复用这里，确保通知文案和监听方式一致。
  Future<void> _startListeningWithEnvironment(EnvironmentType environment) {
    return clipboardManager.startListening(
      env: environment,
      way: appConfig.clipboardListeningWay,
      notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
    );
  }

  /// 弹出 Shizuku 断开通知。
  ///
  /// binder dead 可能发生在后台，必须通过系统通知明确告知用户；短时间内多次回调只保留最近一次。
  Future<void> _notifyShizukuDisconnected() async {
    final now = DateTime.now();
    final lastNotifyAt = _lastShizukuDisconnectedNotifyAt;
    if (lastNotifyAt != null && now.difference(lastNotifyAt) < _shizukuDisconnectedNotifyMinInterval) {
      return;
    }
    _lastShizukuDisconnectedNotifyAt = now;
    try {
      final notifyId = await NotifyUtil.notify(
        title: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedTitle.tr,
        content: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedText.tr,
        key: _shizukuDisconnectedNotifyKey,
      );
      if (notifyId != null) {
        NotifyUtil.cancelExcludeLast(_shizukuDisconnectedNotifyKey);
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }

  /// 展示 Shizuku 自动授权失败提示。
  ///
  /// 仅自动恢复流程使用该提示，避免和工作模式选择页自己的失败提示重复。
  Future<void> _showShizukuRequestFailedDialog() async {
    if (_showingShizukuRequestFailedDialog || Get.context == null) return;
    _showingShizukuRequestFailedDialog = true;
    DialogController? dialog;
    dialog = await Global.showTipsDialog(
      context: Get.context!,
      title: TranslationKey.requestFailed.tr,
      text: TranslationKey.shizukuRequestFailedDialogText.tr,
      showCancel: false,
      autoDismiss: false,
      onOk: () {
        _showingShizukuRequestFailedDialog = false;
        dialog?.close();
      },
    );
  }

  @override
  void onClose() {
    clipboardManager.removeListener(this);
    _clickOutsideSubscription?.cancel();
    _detector.dispose();
    super.onClose();
  }
}
