import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/desktop/window/window_control_clicked_listener.dart';
import 'package:clipshare/core/platform/desktop/window/window_control_state.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'window_control_provider.g.dart';

/// 桌面端窗体控制（最大化/最小化/关闭等）运行时能力。
@Riverpod(keepAlive: true)
class WindowControlNotifier extends _$WindowControlNotifier {
  static const _tag = 'WindowControlNotifier';
  final List<WindowControlClickedListener> _listeners = [];

  @override
  WindowControlState build() => const WindowControlState();

  /// 注册窗体控制按钮点击监听
  void addListener(WindowControlClickedListener listener) {
    if (_listeners.contains(listener)) {
      return;
    }
    _listeners.add(listener);
  }

  /// 移除窗体控制按钮点击监听。
  void removeListener(WindowControlClickedListener listener) {
    _listeners.remove(listener);
  }

  /// 从系统同步当前窗体尺寸与按钮可用性。
  Future<void> syncWindowState() async {
    if (!isDesktop) {
      return;
    }
    final maximized = await windowManager.isMaximized();
    final closeable = await windowManager.isClosable();
    final minimizable = await windowManager.isMinimizable();
    final maximizable = await windowManager.isMaximizable();
    final resizable = await windowManager.isResizable();
    state = state.copyWith(
      maxWindow: maximized,
      closeable: closeable,
      minimizable: minimizable,
      maximizable: maximizable,
      resizable: resizable,
    );
  }

  /// 设置是否允许最小化。
  Future<void> setMinimizable(bool minimizable) async {
    if (!isDesktop) {
      return;
    }
    await windowManager.setMinimizable(minimizable);
    state = state.copyWith(minimizable: minimizable);
  }

  /// 设置是否允许最大化。
  Future<void> setMaximizable(bool maximizable) async {
    if (!isDesktop) {
      return;
    }
    await windowManager.setMaximizable(maximizable);
    state = state.copyWith(maximizable: maximizable);
  }

  /// 设置是否允许关闭。
  Future<void> setCloseable(bool closeable) async {
    if (!isDesktop) {
      return;
    }
    await windowManager.setClosable(closeable);
    state = state.copyWith(closeable: closeable);
  }

  /// 设置是否允许调整窗体大小。
  Future<void> setResizable(bool resizable) async {
    if (!isDesktop) {
      return;
    }
    await windowManager.setResizable(resizable);
    state = state.copyWith(resizable: resizable);
  }

  /// 最大化窗口并通知监听者。
  Future<void> maximize() async {
    if (!isDesktop) {
      return;
    }
    await windowManager.maximize();
    state = state.copyWith(maxWindow: true);
    _notifyListeners((listener) => listener.onMaximizeBtnClicked());
  }

  /// 最小化窗口并通知监听者。
  Future<void> minimize() async {
    if (!isDesktop) {
      return;
    }
    await windowManager.minimize();
    state = state.copyWith(maxWindow: false);
    _notifyListeners((listener) => listener.onMinimizeBtnClicked());
  }

  /// 还原最大化窗口并通知监听者。
  Future<void> unMaximize() async {
    if (!isDesktop) {
      return;
    }
    await windowManager.unmaximize();
    state = state.copyWith(maxWindow: false);
    _notifyListeners((listener) => listener.onUnMaximizeBtnClicked());
  }

  /// 关闭或隐藏窗口并通知监听者。
  ///
  /// [isHide] 为 true 时隐藏窗口，否则真正关闭。
  Future<void> close([bool isHide = false]) async {
    if (!isDesktop) {
      return;
    }
    if (isHide) {
      await windowManager.hide();
    } else {
      await windowManager.close();
    }
    _notifyListeners((listener) => listener.onCloseBtnClicked(isHide));
  }

  /// 设置窗口是否置顶，并同步 [WindowControlState.alwaysOnTop]。
  Future<void> setAlwaysOnTop(bool top) async {
    if (!isDesktop) {
      return;
    }
    await windowManager.setAlwaysOnTop(top);
    state = state.copyWith(alwaysOnTop: top);
  }

  /// 设置历史弹窗是否固定（固定后失焦不自动关闭）。
  void setHistoryPopupPinned(bool pinned) {
    state = state.copyWith(historyPopupPinned: pinned);
  }

  /// 快照遍历，避免回调内增删 listener 触发 ConcurrentModificationError。
  void _notifyListeners(void Function(WindowControlClickedListener listener) action) {
    for (final listener in List<WindowControlClickedListener>.of(_listeners)) {
      try {
        action(listener);
      } catch (err, stack) {
        logger.error(_tag, err, stack);
      }
    }
  }
}
