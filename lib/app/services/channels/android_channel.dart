import 'dart:io';

import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/channelMethods/android_channel_method.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AndroidChannelService extends GetxService {
  static const tag = "AndroidChannelService";
  late final MethodChannel androidChannel;
  final appConfig = Get.find<ConfigService>();

  AndroidChannelService init() {
    androidChannel = appConfig.androidChannel;
    if (Platform.isAndroid) {
      if (appConfig.showHistoryFloat) {
        showHistoryFloatWindow();
      }
      lockHistoryFloatLoc(
        {"loc": appConfig.lockHistoryFloatLoc},
      );
    }
    return this;
  }

  /// 通知 Android 媒体库刷新
  void notifyMediaScan(String path) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(AndroidChannelMethod.notifyMediaScan.name, {
      "imagePath": path,
    });
  }

  /// 授权Shizuku权限
  Future<void> grantShizukuPermission(BuildContext ctx) async {
    if (!Platform.isAndroid) return;
    await clipboardManager.requestPermission(EnvironmentType.shizuku);
  }

  /// 检查 Shizuku权限
  Future<bool?> checkShizukuPermission() {
    if (!Platform.isAndroid) return Future(() => false);
    return clipboardManager.checkPermission(EnvironmentType.shizuku);
  }

  /// 显示历史悬浮窗
  void showHistoryFloatWindow() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.showHistoryFloatWindow.name,
    );
  }

  /// 关闭历史悬浮窗
  void closeHistoryFloatWindow() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.closeHistoryFloatWindow.name,
    );
  }

  /// 锁定历史悬浮窗位置
  void lockHistoryFloatLoc(dynamic data) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.lockHistoryFloatLoc.name,
      data,
    );
  }

  /// 回到桌面
  void moveToBg() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.moveToBg.name,
    );
  }

  /// toast
  void toast(String text) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.toast.name,
      {"content": text},
    );
  }

  /// 发送通知
  Future<int?> sendNotify(String content) {
    if (!Platform.isAndroid) return Future.value(null);
    return androidChannel.invokeMethod<int?>(
      AndroidChannelMethod.sendNotify.name,
      {"content": content},
    );
  }

  /// 发送通知
  Future<void> cancelNotify(int id) {
    if (!Platform.isAndroid) return Future.value();
    return androidChannel.invokeMethod(
      AndroidChannelMethod.cancelNotify.name,
      {"id": id},
    );
  }

  ///复制content文件到指定路径
  Future<String?> copyFileFromUri(String content, String savedPath) {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.copyFileFromUri.name,
      {
        "content": content,
        "savedPath": savedPath,
      },
    );
  }

  ///开启短信监听
  Future<void> startSmsListen() {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.startSmsListen.name,
    );
  }

  ///关闭短信监听
  Future<void> stopSmsListen() {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.stopSmsListen.name,
    );
  }

  ///设置是否在最近任务中隐藏
  Future<bool> showOnRecentTasks(bool show) {
    if (!Platform.isAndroid) return Future.value(false);
    return androidChannel
        .invokeMethod<bool?>(
          AndroidChannelMethod.showOnRecentTasks.name,
          {
            "show": show,
          },
        )
        .then((v) => v ?? false);
  }

  ///返回媒体库中的最新一张图片路径
  Future<String?> getLatestImagePath() {
    if (!Platform.isAndroid) return Future.value(null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.getLatestImagePath.name,
      {},
    );
  }

  ///启用启动上传崩溃日志
  Future<void> setAutoReportCrashes(bool checked) {
    if (!Platform.isAndroid) return Future.value(null);
    return androidChannel.invokeMethod(
      AndroidChannelMethod.setAutoReportCrashes.name,
      {"enable": checked},
    );
  }

  void sendBigImageNotify() {
    androidChannel.invokeMethod('sendBigImageNotification');
  }
}
