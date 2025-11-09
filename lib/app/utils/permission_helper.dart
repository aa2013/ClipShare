import 'dart:io';

import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class PermissionHelper {
  PermissionHelper._private();

  static const tag = "PermissionHelper";

  ///测试存储权限
  static Future<bool> testAndroidStoragePerm([String? dirPath]) async {
    if (!Platform.isAndroid) return true;
    final appConfig = Get.find<ConfigService>();
    dirPath = dirPath ?? appConfig.rootStorePath;
    bool isGranted = false;
    if (appConfig.osVersion >= 13) {
      isGranted = await Permission.manageExternalStorage.isGranted;
    } else {
      isGranted = await Permission.storage.isGranted;
    }
    if (isGranted && _testFileOperate(dirPath)) {
      return true;
    }
    if (appConfig.osVersion >= 11 &&
        !dirPath.startsWith(Constants.androidDownloadPath)) {
      isGranted = await Permission.manageExternalStorage.isGranted;
      if (isGranted && _testFileOperate(dirPath)) {
        return true;
      }
    }
    return false;
  }

  ///请求Android存储权限
  static Future<void> reqAndroidStoragePerm([String? dirPath]) async {
    if (!Platform.isAndroid) return;
    final appConfig = Get.find<ConfigService>();
    dirPath = dirPath ?? appConfig.rootStorePath;
    if (!dirPath.startsWith(Constants.androidDownloadPath)) {
      var status = await Permission.manageExternalStorage.request();
      Log.info(tag, "request manageExternalStoragePermission: $status");
    }
    late final PermissionStatus status;
    if (appConfig.osVersion >= 13) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    Log.info(tag, "request storagePermission: $status");
  }

  ///测试文件操作
  static bool _testFileOperate(String dirPath) {
    //尝试创建文件夹和文件
    var dir = Directory(dirPath);
    if (dir.existsSync()) {
      try {
        var file = File("$dirPath/${const Uuid()}");
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
    Log.info(tag, "request AndroidReadSms: $status");
  }

  ///测试Android相机权限
  static Future<bool> testAndroidCameraPerm() async {
    if (!Platform.isAndroid) return false;
    return await Permission.camera.isGranted;
  }

  ///请求Android相机权限
  static Future<void> reqAndroidCameraPerm() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.camera.request();
    Log.info(tag, "request Android camera: $status");
  }

  ///测试无障碍权限
  static Future<bool> testAndroidAccessibilityPerm() async {
    if (!Platform.isAndroid) return false;
    return await clipboardManager.checkAccessibility();
  }

  ///请求无障碍权限
  static Future<void> reqAndroidAccessibilityPerm() async {
    if (!Platform.isAndroid) return;
    return await clipboardManager.requestAccessibility();
  }
}
