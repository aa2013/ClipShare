import 'package:clipshare/app/listeners/window_control_clicked_listener.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowControlService extends GetxService {
  final maxWindow = false.obs;
  final closeBtnHovered = false.obs;
  final maximizable = false.obs;
  final minimizable = false.obs;
  final closeable = true.obs;
  final resizable = false.obs;
  final alwaysOnTop = false.obs;
  final List<WindowControlClickedListener> _listeners = [];

  void addListener(WindowControlClickedListener listener) {
    _listeners.add(listener);
  }

  void removeListener(WindowControlClickedListener listener) {
    _listeners.remove(listener);
  }

  ///初始化窗体尺寸信息
  Future<WindowControlService> initWindows() async {
    if (PlatformExt.isMobile) return this;
    await windowManager.isMaximized().then((maximized) {
      maxWindow.value = maximized;
    });
    await windowManager.isClosable().then((closeable) {
      this.closeable.value = closeable;
    });
    await windowManager.isMinimizable().then((minimizable) {
      this.minimizable.value = minimizable;
    });
    await windowManager.isMaximizable().then((maximizable) {
      this.maximizable.value = maximizable;
    });
    await windowManager.isResizable().then((resizable) {
      this.resizable.value = resizable;
    });
    return this;
  }

  Future<void> setMinimizable(bool minimizable) async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.setMinimizable(minimizable);
    this.minimizable.value = minimizable;
  }

  Future<void> setMaximizable(bool maximizable) async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.setMaximizable(maximizable);
    this.maximizable.value = maximizable;
  }

  Future<void> setCloseable(bool closeable) async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.setClosable(closeable);
    this.closeable.value = closeable;
  }

  Future<void> setResizable(bool resizable) async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.setResizable(resizable);
    this.resizable.value = resizable;
  }

  Future<void> maximize() async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.maximize();
    maxWindow.value = true;
    for (var listener in _listeners) {
      try {
        listener.onMaximizeBtnClicked();
      } catch (_) {}
    }
  }

  Future<void> minimize() async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.minimize();
    maxWindow.value = false;
    for (var listener in _listeners) {
      try {
        listener.onMinimizeBtnClicked();
      } catch (_) {}
    }
  }

  Future<void> unMaximize() async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.unmaximize();
    maxWindow.value = false;
    for (var listener in _listeners) {
      try {
        listener.onUnMaximizeBtnClicked();
      } catch (_) {}
    }
  }

  Future<void> close([bool isHide = false]) async {
    if (isHide) {
      await windowManager.hide();
    } else {
      await windowManager.close();
    }
    for (var listener in _listeners) {
      try {
        listener.onCloseBtnClicked(isHide);
      } catch (_) {}
    }
  }

  Future<void> setAlwaysOnTop(bool top) async {
    if (!PlatformExt.isDesktop) return;
    await windowManager.setAlwaysOnTop(top);
    this.alwaysOnTop.value = false;
  }
}
