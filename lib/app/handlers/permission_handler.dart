import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class AbstractPermissionHandler {
  static void showRequestDialog({
    required String title,
    required Widget content,
    required bool Function(BuildContext) onConfirm,
    void Function(BuildContext)? onClose,
    bool allowCloseInBlank = false,
    String? closeText,
    String? confirmText,
  }) {
    showDialog(
      context: Get.context!,
      barrierDismissible: allowCloseInBlank,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: [
            TextButton(
              onPressed: () {
                // 关闭弹窗
                Navigator.pop(context);
                onClose?.call(context);
              },
              child: Text(closeText ?? TranslationKey.dialogCancelText.tr),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm.call(context)) {
                  // 关闭弹窗
                  Navigator.pop(context);
                }
              },
              child: Text(confirmText ??
                  TranslationKey.dialogAuthorizationButtonText.tr),
            ),
          ],
        );
      },
    );
  }

  void request();

  Future<bool> hasPermission();
}

///悬浮窗权限处理请求
class FloatPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: TranslationKey.floatPermRequestDialogTitle.tr,
      content: Text(
        TranslationKey.floatPermRequestDialogContent.tr,
      ),
      onClose: (ctx) {
        Global.showTipsDialog(
          context: ctx,
          title: TranslationKey.requiredPermDialogTitle.tr,
          text: TranslationKey.floatPermMissingDialogContent.tr,
        );
      },
      onConfirm: (ctx) {
        final androidChannelService = Get.find<AndroidChannelService>();
        androidChannelService.androidChannel
            .invokeMethod<bool>("grantAlertWindowPermission")
            .then((res) async {
          if (await hasPermission()) return;
          Global.showTipsDialog(
            context: ctx,
            title: TranslationKey.requiredPermDialogTitle.tr,
            text: TranslationKey.floatPermMissingDialogContent.tr,
          );
        });
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.androidChannel
        .invokeMethod<bool>("checkAlertWindowPermission");
    if (res == null) return false;
    return res;
  }
}

///Shizuku权限处理请求
class ShizukuPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    final appConfig = Get.find<ConfigService>();
    final androidChannelService = Get.find<AndroidChannelService>();
    AbstractPermissionHandler.showRequestDialog(
      title: TranslationKey.shizukuPermRequestDialogTitle.tr,
      content: Text(
        TranslationKey.shizukuPermRequestDialogContent.tr,
      ),
      closeText: appConfig.ignoreShizuku
          ? TranslationKey.dialogCancelText.tr
          : TranslationKey.dontShowAgain.tr,
      onClose: (ctx) {
        if (appConfig.ignoreShizuku) {
          return;
        }
        Global.showTipsDialog(
          context: ctx,
          text: TranslationKey.dontShowAgainConfirm.tr,
          showCancel: true,
          onOk: () async {
            appConfig.setIgnoreShizuku();
          },
        );
      },
      onConfirm: (ctx) {
        androidChannelService.grantShizukuPermission(ctx);
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.checkShizukuPermission();
    if (res == null) return false;
    return res;
  }
}

///通知权限处理请求
class NotifyPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    if(!Platform.isAndroid && !Platform.isIOS) return;
    if(Platform.isAndroid){
      AbstractPermissionHandler.showRequestDialog(
          title: TranslationKey.notificationPermRequestDialogTitle.tr,
          content: Text(
            TranslationKey.notificationPermRequestDialogContent.tr,
          ),
          onConfirm: (ctx) {
            final androidChannelService = Get.find<AndroidChannelService>();
            androidChannelService.androidChannel
                .invokeMethod<bool>("grantNotification")
                .then((hasPerm) {
              //启动服务
              androidChannelService.androidChannel.invokeMethod("startService");
            });
            return true;
          },
        );
    } else {
      PermissionHelper.reqIOSNotificationPermission();
    }
  }

  @override
  Future<bool> hasPermission() async {
    if(!Platform.isAndroid && !Platform.isIOS) return false;
    if(Platform.isAndroid){
      final androidChannelService = Get.find<AndroidChannelService>();
      var res = await androidChannelService.androidChannel.invokeMethod<bool>("checkNotification");
      if (res == null) return false;
      return res;
    }else{
      return PermissionHelper.checkIOSNotificationPermission();
    }
  }
}

///电池优化权限处理请求
class IgnoreBatteryHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: TranslationKey.batteryOptimization.tr,
      content: Text(
        TranslationKey.batteryOptimizationPermRequestDialogContent.tr,
      ),
      onConfirm: (ctx) {
        Permission.ignoreBatteryOptimizations.request();
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    return Permission.ignoreBatteryOptimizations.isGranted;
  }
}

///IOS 相册权限
class IosPhotosHandler extends AbstractPermissionHandler{
  @override
  Future<bool> hasPermission() async {
    if(!Platform.isIOS) return false;
    return await PermissionHelper.checkIOSPhotoPermission();
  }

  @override
  void request() {
    if(!Platform.isIOS) return;
    PermissionHelper.reqIOSPhotoPermission();
  }

}