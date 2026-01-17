import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService with WindowListener {
  final tag = "WindowService";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  Future<WindowService> init() async {
    windowManager.addListener(this);
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    return this;
  }

  void showApp() {
    if(Platform.isMacOS){
      windowManager.setSkipTaskbar(false);
    }
    windowManager.setPreventClose(true).then((value) {
      windowManager.show();
    });
  }

  void exitApp() {
    windowManager.setPreventClose(false).then((value) {
      appConfig.historyWindow?.close();
      appConfig.onlineDevicesWindow?.close();
      windowManager.hide();
      windowManager.close();
      Get.deleteAll(force: true);
      exit(0);
    });
  }

  @override
  void onClose() {
    windowManager.removeListener(this);
    super.onClose();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
    if(Platform.isMacOS){
      windowManager.setSkipTaskbar(true);
    }
    Log.debug(tag, "onClose");
  }

  @override
  void onWindowResized() {
    if (!appConfig.rememberWindowSize) {
      return;
    }
    windowManager.getSize().then((size) {
      appConfig.setWindowSize(size);
    });
  }
}
