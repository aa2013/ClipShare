import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/history/history_event.dart';
import 'package:clipshare/core/history/history_recorder_provider.dart';
import 'package:clipshare/core/notify/notify_provider.dart';
import 'package:clipshare/core/settings/float/float_window_settings_provider.dart';
import 'package:clipshare/core/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/drop/my_drop_item.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

import 'android_channel_method.dart';

part 'android_channel_method_call.dart';

part 'android_channel_provider.g.dart';

@Riverpod(keepAlive: true)
class AndroidChannelNotifier extends _$AndroidChannelNotifier {
  static const tag = 'AndroidChannelNotifier';
  late final MethodChannel _channel;

  @override
  void build() {
    _channel = const MethodChannel(channelAndroid);
    _channel.setMethodCallHandler((call) => _onMethodCall(ref, call));
  }

  /// 通知 Android 媒体库刷新
  void notifyMediaScan(String path) {
    if (!isAndroid) return;
    _channel.invokeMethod(AndroidChannelMethod.notifyMediaScan.name, {
      'imagePath': path,
    });
  }

  /// 授权Shizuku权限
  Future<void> grantShizukuPermission(BuildContext ctx) async {
    if (!isAndroid) return;
    await clipboardManager.requestPermission(EnvironmentType.shizuku);
  }

  /// 检查 Shizuku权限
  Future<bool?> checkShizukuPermission() {
    if (!isAndroid) return Future(() => false);
    return clipboardManager.checkPermission(EnvironmentType.shizuku);
  }

  /// 显示历史悬浮窗
  void showHistoryFloatWindow() {
    if (!isAndroid) return;
    final floatWindowSettings = ref.read(floatWindowSettingsProvider).requireValue;
    final quickSettings = ref.read(quickSettingsProvider).requireValue;
    _channel.invokeMethod(
      AndroidChannelMethod.showHistoryFloatWindow.name,
      {
        'width': floatWindowSettings.historyFloatHandleWidth,
        'color': floatWindowSettings.historyFloatHandleColor,
        'applyAlphaToWholeHandle': floatWindowSettings.historyFloatHandleApplyAlphaToWholeHandle,
        'themeMode': quickSettings.appTheme.name,
        'i18n': {
          'title': TranslationKey.historyFloatTitle.tr,
          'countTemplate': TranslationKey.historyFloatCountTemplate.tr,
          'imageUnavailable': TranslationKey.historyFloatImageUnavailable.tr,
          'textType': TranslationKey.text.tr,
          'imageType': TranslationKey.image.tr,
          'fileType': TranslationKey.file.tr,
        },
      },
    );
  }

  /// 关闭历史悬浮窗
  void closeHistoryFloatWindow() {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.closeHistoryFloatWindow.name,
    );
  }

  void setHistoryFloatHandleWidth(int width) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.setHistoryFloatHandleWidth.name,
      {'width': width},
    );
  }

  void setHistoryFloatHandleColor(int color) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.setHistoryFloatHandleColor.name,
      {'color': color},
    );
  }

  /// 同步把手装饰层是否跟随用户所选颜色透明度。
  void setHistoryFloatHandleApplyAlphaToWholeHandle(bool value) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.setHistoryFloatHandleApplyAlphaToWholeHandle.name,
      {'applyAlphaToWholeHandle': value},
    );
  }

  /// 同步历史悬浮窗主题，运行中的 Android 原生浮窗会即时切换亮暗色。
  void setHistoryFloatThemeMode(ThemeMode mode) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.setHistoryFloatThemeMode.name,
      {'themeMode': mode.name},
    );
  }

  Future<bool> checkAlertWindowPermission() async {
    if (!isAndroid) return false;
    return await _channel.invokeMethod<bool?>(AndroidChannelMethod.checkAlertWindowPermission.name).then((v) => v ?? false);
  }

  Future<void> grantAlertWindowPermission() {
    if (!isAndroid) return Future.value();
    return _channel.invokeMethod(
      AndroidChannelMethod.grantAlertWindowPermission.name,
    );
  }

  void showKeepAliveFloatWindow() {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.showKeepAliveFloatWindow.name,
    );
  }

  void closeKeepAliveFloatWindow() {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.closeKeepAliveFloatWindow.name,
    );
  }

  /// 锁定历史悬浮窗位置
  void lockHistoryFloatLoc(dynamic data) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.lockHistoryFloatLoc.name,
      data,
    );
  }

  /// 回到桌面
  void moveToBg() {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.moveToBg.name,
    );
  }

  /// toast
  void toast(String text) {
    if (!isAndroid) return;
    _channel.invokeMethod(
      AndroidChannelMethod.toast.name,
      {'content': text},
    );
  }

  /// 发送通知
  Future<int?> sendNotify(String title, String content) {
    if (!isAndroid) return Future.value(null);
    return _channel.invokeMethod<int?>(
      AndroidChannelMethod.sendNotify.name,
      {
        'title': title,
        'content': content,
      },
    );
  }

  /// 发送通知
  Future<void> cancelNotify(int id) {
    if (!isAndroid) return Future.value();
    return _channel.invokeMethod(
      AndroidChannelMethod.cancelNotify.name,
      {'id': id},
    );
  }

  ///复制content文件到指定路径
  Future<String?> copyFileFromUri(String content, String savedPath) {
    if (!isAndroid) return Future(() => null);
    return _channel.invokeMethod<String?>(
      AndroidChannelMethod.copyFileFromUri.name,
      {
        'content': content,
        'savedPath': savedPath,
      },
    );
  }

  ///开启短信监听
  Future<void> startSmsListen() {
    if (!isAndroid) return Future(() => null);
    return _channel.invokeMethod<String?>(
      AndroidChannelMethod.startSmsListen.name,
    );
  }

  ///关闭短信监听
  Future<void> stopSmsListen() {
    if (!isAndroid) return Future(() => null);
    return _channel.invokeMethod<String?>(AndroidChannelMethod.stopSmsListen.name);
  }

  ///设置是否在最近任务中隐藏
  Future<bool> showOnRecentTasks(bool show) async {
    if (!isAndroid) return Future.value(false);
    return await _channel
        .invokeMethod<bool?>(
          AndroidChannelMethod.showOnRecentTasks.name,
          {
            'show': show,
          },
        )
        .then((v) => v ?? false);
  }

  ///返回媒体库中的最新一张图片路径
  Future<String?> getLatestImagePath() {
    if (!isAndroid) return Future.value(null);
    return _channel.invokeMethod<String?>(
      AndroidChannelMethod.getLatestImagePath.name,
      {},
    );
  }

  ///启用启动上传崩溃日志
  Future<void> setAutoReportCrashes(bool checked) {
    if (!isAndroid) return Future.value(null);
    return _channel.invokeMethod(
      AndroidChannelMethod.setAutoReportCrashes.name,
      {'enable': checked},
    );
  }

  void sendHistoryChangedBroadcast(HistoryContentType type, String content, String fromDevId, String fromDevName) {
    _channel.invokeMethod(AndroidChannelMethod.sendHistoryChangedBroadcast.name, {
      'type': type.name,
      'content': content,
      'from_dev_id': fromDevId,
      'from_dev_name': fromDevName,
    });
  }
}
