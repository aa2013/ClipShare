import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService with WindowListener {
  final tag = "WindowService";
  final appConfig = Get.find<ConfigService>();

  Future<WindowService> init() async {
    windowManager.addListener(this);
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    return this;
  }

  void showApp() {
    windowManager.setPreventClose(true).then((value) {
      windowManager.show();
    });
  }

  void exitApp() {
    windowManager.setPreventClose(false).then((value) {
      appConfig.historyWindow?.close();
      windowManager.hide();
      WindowManager.instance.destroy();
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
    Log.debug(tag, "onClose");
  }

  @override
  void onWindowResized() {
    if (!appConfig.rememberWindowSize) {
      return;
    }
    print("111");
    windowManager.getSize().then((size) {
      appConfig.setWindowSize(size);
    });
  }
}
