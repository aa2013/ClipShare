import 'dart:io';

import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/windows_win_v_takeover.dart';
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

  Future<void> exitApp() async {
    await windowManager.setPreventClose(false);
    await _releaseHotKeysBeforeExit();
    await _restoreWinVBeforeExit();
    appConfig.historyWindow?.close();
    appConfig.onlineDevicesWindow?.close();
    windowManager.hide();
    windowManager.close();
    Get.deleteAll(force: true);
    exit(0);
  }

  ///退出前释放应用注册的全局快捷键，确保 Explorer 重启时能重新接管 Win+V。
  Future<void> _releaseHotKeysBeforeExit() async {
    try {
      await AppHotKeyHandler.unRegisterAll();
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }

  ///正常退出前恢复 Win+V，避免接管状态在 Explorer 中长期残留。
  Future<void> _restoreWinVBeforeExit() async {
    if (!Platform.isWindows || !appConfig.takeOverWinV) {
      return;
    }
    try {
      final changed = await restoreWinV();
      if (changed) {
        await restartExplorer();
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
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
    logger.debug(tag, "onClose");
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
