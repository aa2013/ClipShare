import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:uuid/uuid.dart';

import 'permission_handler_facade.dart';

class PermissionHelper {
  PermissionHelper._private();

  static const tag = 'PermissionHelper';

  ///测试存储权限
  static Future<bool> testAndroidStoragePerm(String rootStorePath,int osVersion,[String? dirPath]) async {
    if (!Platform.isAndroid) return true;
    dirPath = dirPath ?? rootStorePath;
    bool isGranted = false;
    if (osVersion >= 13) {
      isGranted = await Permission.manageExternalStorage.isGranted;
    } else {
      isGranted = await Permission.storage.isGranted;
    }
    if (isGranted && _testFileOperate(dirPath)) {
      return true;
    }
    if (osVersion >= 11 && !dirPath.startsWith(androidDownloadPath)) {
      isGranted = await Permission.manageExternalStorage.isGranted;
      if (isGranted && _testFileOperate(dirPath)) {
        return true;
      }
    }
    return false;
  }

  ///请求Android存储权限
  static Future<void> reqAndroidStoragePerm(String rootStorePath,int osVersion, [String? dirPath]) async {
    if (!Platform.isAndroid) return;
    dirPath = dirPath ?? rootStorePath;
    if (!dirPath.startsWith(androidDownloadPath)) {
      var status = await Permission.manageExternalStorage.request();
      logger.info(tag, 'request manageExternalStoragePermission: $status');
    }
    late final PermissionStatus status;
    if (osVersion >= 13) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    logger.info(tag, 'request storagePermission: $status');
  }

  ///测试文件操作
  static bool _testFileOperate(String dirPath) {
    //尝试创建文件夹和文件
    var dir = Directory(dirPath);
    if (dir.existsSync()) {
      try {
        var file = File('$dirPath/${const Uuid()}');
        file.createSync();
        file.deleteSync();
        return true;
      } catch (e) {
        return false;
      }
    } else {
      try {
        dir.createSync(recursive: true);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  ///Android短信读取权限
  static Future<bool> testAndroidReadSms() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  ///Android短信读取权限请求
  static Future<void> reqAndroidReadSms() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.sms.request();
    logger.info(tag, 'request AndroidReadSms: $status');
  }

  ///测试相机权限
  static Future<bool> testCameraPerm() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return await Permission.camera.isGranted;
  }

  ///请求相机权限
  static Future<void> reqCameraPerm() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    var status = await Permission.camera.request();
    logger.info(tag, 'request camera: $status');
  }

  ///检查IOS相册权限
  static Future<bool> checkIOSPhotoPermission() async {
    if(!Platform.isIOS) return false;
    var status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  ///请求IOS相册权限
  static Future<bool> reqIOSPhotoPermission() async {
    if(!Platform.isIOS) return false;
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  ///检查IOS通知权限
  static Future<bool> checkIOSNotificationPermission() async {
    if(!Platform.isIOS) return false;
    var status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  ///请求IOS通知权限
  static Future<bool> reqIOSNotificationPermission() async {
    if(!Platform.isIOS) return false;
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  ///测试无障碍权限
  static Future<bool> testAndroidAccessibilityPerm() async {
    if (!Platform.isAndroid) return false;
    return await clipboardManager.checkAccessibility();
  }

  ///静默尝试自动授予无障碍权限，不成功时不跳转系统设置
  static Future<bool> tryAutoGrantAndroidAccessibilityPerm() async {
    if (!Platform.isAndroid) return false;
    //插件内部特权命令环境跟随剪贴板监听启动环境，这里只声明是否自动授权
    return await clipboardManager.requestAccessibility(autoGrant: true);
  }

  ///请求无障碍权限，自动授权失败时回退到系统设置页
  static Future<bool> reqAndroidAccessibilityPerm() async {
    if (!Platform.isAndroid) return false;
    final granted = await tryAutoGrantAndroidAccessibilityPerm();
    if (granted) return true;
    //没有 Shizuku/root 能力或自动写入失败时，回退到旧的手动授权流程
    await clipboardManager.requestAccessibility();
    return false;
  }
}
