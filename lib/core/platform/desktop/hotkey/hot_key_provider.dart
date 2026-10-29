import 'dart:async';

import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/desktop/hotkey/windows_win_v_takeover.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/hot_key_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/hotkey_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'hot_key_provider.g.dart';

@Riverpod(keepAlive: true)
class HotKeyNotifier extends _$HotKeyNotifier {
  static const tag = 'HotKeyNotifier';

  /// 退出程序热键触发的通知 key
  static const exitAppNotifyKey = 'appExit';

  /// 退出程序通知展示时长，到时自动取消
  static final exitAppNotifyDuration = 2.s;

  final _hotkeyMap = <HotKeyType, HotKey>{};

  HotkeySettings get _hotKeySettings => ref.read(hotkeySettingsProvider).requireValue;

  TrayNotifier get _tray => ref.read(trayProvider.notifier);

  NotifyNotifier get _notify => ref.read(notifyProvider.notifier);

  @override
  Future<void> build() async {
    ref.onDispose(_dispose);
    if (!isDesktop) {
      return;
    }
    await _init();
  }

  /// 获取指定类型当前已注册的热键
  HotKey? getByType(HotKeyType type) {
    return _hotkeyMap[type];
  }

  /// 历史弹窗热键
  Future<void> registerHistoryWindow(HotKey key) async {
    await unRegister(HotKeyType.historyWindow);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        //todo 多窗口功能迁移完成后恢复以下按键处理逻辑，恢复时需要：
        // 1) MultiWindowChannelNotifier 暴露 historyWindow 窗口引用
        // 2) 补充内部 getter：_multiWindowChannel、_preferenceSettings、_localDeviceInfo
        // 3) DesktopMultiWindowArgs.init 按当前签名补传必填 locale 参数
        // 4) 补充依赖 import：dart:math、dart:ui、screen_retriever、desktop_multi_window、
        //    MultiWindowTag/MultiWindowConfig/DesktopMultiWindowArgs、appThemeProvider
        // final multiWindowService = _multiWindowChannel;
        // final preferenceSettings = _preferenceSettings;
        // var ids = List.empty();
        // try {
        //   ids = await DesktopMultiWindow.getAllSubWindowIds();
        // } catch (e) {
        //   ids = List.empty();
        // }
        // //只允许弹窗一次
        // final windowId = multiWindowService.historyWindow?.windowId;
        // final isHide = multiWindowService.isHideWindow(windowId);
        // bool isRelocate = false;
        // if (ids.contains(windowId) && !isHide) {
        //   //偏好为使用相同快捷键关闭
        //   if (preferenceSettings.closeOnSameHotKey) {
        //     // 用 hideChildWindow 替代 closeWindow：closeWindow 里的 windowManager.hide()
        //     // 在主窗口 isolate 执行会隐藏主窗口（而非弹窗），导致按 Win+V 时主界面被关闭。
        //     // hideChildWindow 只发 IPC 让子窗口自隐藏，主窗口不受影响。
        //     await multiWindowService.hideChildWindow(windowId!, MultiWindowTag.history).catchError((err) {
        //       logger.warn(tag, "hideChildWindow failed: $err");
        //     });
        //     return;
        //   }
        //   // 偏好为不关闭：不 hide 弹窗，直接重新定位到光标处（下方 showWindowFromHide 会 setPosition）。
        //   // 避免隐藏 active 弹窗触发前台窗口变化，被 onForegroundChanged 误判为切走而关闭（闪一下消失）。
        //   isRelocate = true;
        // }
        // var posCfg = preferenceSettings.historyDialogPosition;
        // var radio = windowManager.getDevicePixelRatio();
        // var offset = await screenRetriever.getCursorScreenPoint();
        // //存储的位置配置不为空则按配置显示
        // if (posCfg != Offset.zero && preferenceSettings.recordHistoryDialogPosition) {
        //   offset = posCfg;
        // }
        // //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器。
        // //已知限制：混合 DPI（主屏 150%+副屏 100%）下 getCursorScreenPoint 除的是
        // //Flutter view 的 DPR 而非光标所在显示器（screen_retriever 上游行为），
        // //换 getDisplayList() 也无法单独修复——多屏垂直判断可能不准，勿误以为是本处 bug。
        // //screenRetriever 的鼠标坐标/屏幕尺寸均为逻辑像素，位置计算用逻辑像素
        // //（原代码乘 devicePixelRatio 会放大尺寸，导致上方空间误判放不下）
        // //visibleSize 为可空（部分驱动/场景取不到），取不到时回退 size
        // final display = await screenRetriever.getPrimaryDisplay();
        // Size screenSize = display.visibleSize ?? display.size;
        // var [width, height] = [370.0, 630.0];
        // if (preferenceSettings.rememberPopupWindowSize && preferenceSettings.historyWindowSize != null) {
        //   final size = preferenceSettings.historyWindowSize!;
        //   width = size.width;
        //   height = size.height;
        // }
        // final maxX = max(screenSize.width - width, 0.0);
        // final maxY = max(screenSize.height - height, 0.0);
        // //弹窗与光标/输入框的垂直间隔：弹上方贴紧光标上方，弹下方贴紧光标下方
        // const gapAbove = 15.0;
        // const gapBelow = 15.0;
        // final x = min(maxX, offset.dx);
        // final double y;
        // if (posCfg != Offset.zero && preferenceSettings.recordHistoryDialogPosition) {
        //   //记忆位置：原样使用（用户已手动调整过弹窗位置）
        //   y = min(maxY, offset.dy);
        // } else {
        //   //跟随鼠标：优先弹在光标/输入框上方（避免遮挡输入框与光标），
        //   //上方空间不足（弹窗较高时普通输入框位置也放不下）才弹到下方
        //   y = offset.dy - height - gapAbove >= 0
        //       ? offset.dy - height - gapAbove
        //       : min(maxY, offset.dy + gapBelow);
        // }
        // if (multiWindowService.historyWindow != null) {
        //   try {
        //     await multiWindowService.showWindowFromHide(
        //       multiWindowService.historyWindow!.windowId,
        //       position: [x, y],
        //       tag: MultiWindowTag.history,
        //       isRelocate: isRelocate,
        //     );
        //   } catch (e) {
        //     // IPC 失败说明子窗口可能已不可用，重置引用以便下次重新创建窗口。
        //     logger.warn(tag, "showWindowFromHide failed, will recreate: $e");
        //     multiWindowService.historyWindow = null;
        //   }
        //   if (multiWindowService.historyWindow != null) {
        //     return;
        //   }
        // }
        // //createWindow里面的参数必须传
        // final title = TranslationKey.historyRecord.tr;
        // final window = await DesktopMultiWindow.createWindow(
        //   DesktopMultiWindowArgs.init(
        //     title: title,
        //     tag: MultiWindowTag.history,
        //     themeMode: await ref.read(appThemeProvider.future),
        //     autoClosePopupOnBlur: _preferenceSettings.autoClosePopupOnBlur,
        //     selfDeviceGuid: _localDeviceInfo.guid,
        //     otherArgs: {MultiWindowConfig.clickToPaste.name: _preferenceSettings.clickToPaste},
        //   ).toString(),
        // );
        // multiWindowService.historyWindow = window;
        // //desktop_multi_window 的 setFrame 走 MoveWindow（物理像素，不乘 DPR），
        // //位置与尺寸须乘 radio 转物理；而 showWindowFromHide 的 position 走
        // //window_manager（逻辑像素），故位置计算用逻辑、setFrame 单独转物理。
        // window
        //   ..setFrame(Offset(x * radio, y * radio) & Size(width * radio, height * radio))
        //   ..setTitle(title)
        //   ..show();
        // //首次创建后补开启点击外部监听（showWindowFromHide 才会走显示路径，
        // //createWindow 路径没有会导致本机重启后第一个弹窗点击外部不关闭）。
        // //放在 setFrame/setTitle/show 之后：把这几步耗时从 300ms 宽限期预算里省出来。
        // multiWindowService.removeHideWindow(window.windowId, MultiWindowTag.history);
      },
    );
    _hotkeyMap[HotKeyType.historyWindow] = key;
  }

  /// 同步文件热键
  Future<void> registerFileSync(HotKey key) async {
    await unRegister(HotKeyType.fileSender);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        //todo 多窗口功能迁移完成后恢复以下按键处理逻辑，恢复时需要：
        // 1) MultiWindowChannelNotifier 暴露 onlineDevicesWindow 窗口引用
        // 2) 补充内部 getter：_multiWindowChannel、_preferenceSettings、_localDeviceInfo
        // 3) DesktopMultiWindowArgs.init 按当前签名补传必填 locale 参数
        // 4) 补充依赖 import：dart:math、dart:io、dart:ui、screen_retriever、desktop_multi_window、
        //    MultiWindowTag/DesktopMultiWindowArgs、clipboard_manager（getSelectedFiles）、appThemeProvider
        // final multiWindowService = _multiWindowChannel;
        // final preferenceSettings = _preferenceSettings;
        // ///快捷键事件
        // final res = await clipboardManager.getSelectedFiles();
        // final files = res.list;
        // List<String> filePaths = List.empty(growable: true);
        // for (var filePath in files) {
        //   FileSystemEntityType type = await FileSystemEntity.type(filePath);
        //   switch (type) {
        //     case FileSystemEntityType.file:
        //       filePaths.add(filePath);
        //       break;
        //     default:
        //   }
        // }
        // var ids = List.empty();
        // try {
        //   ids = await DesktopMultiWindow.getAllSubWindowIds();
        // } catch (e) {
        //   ids = List.empty();
        // }
        // final windowId = multiWindowService.onlineDevicesWindow?.windowId;
        // final isHide = multiWindowService.isHideWindow(windowId);
        // //只允许弹窗一次
        // if (ids.contains(windowId) && !isHide) {
        //   // 同 history：主窗口 isolate 调 closeWindow 会隐藏主窗口，改用 hideChildWindow
        //   await multiWindowService.hideChildWindow(windowId!, MultiWindowTag.devices).catchError((err) {
        //     logger.warn(tag, "hideChildWindow failed: $err");
        //   });
        //   //偏好为使用相同快捷键关闭，直接结束
        //   if (preferenceSettings.closeOnSameHotKey) {
        //     return;
        //   }
        // }
        // var radio = windowManager.getDevicePixelRatio();
        // var offset = await screenRetriever.getCursorScreenPoint();
        // //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器。
        // //混合 DPI 限制同 history 分支（getCursorScreenPoint 除的是 Flutter view 的 DPR）。
        // //screenRetriever 的鼠标坐标/屏幕尺寸均为逻辑像素，位置计算用逻辑像素
        // //（与 history 同款修复：原乘 devicePixelRatio 会把尺寸放大，首次创建位置偏左上）
        // //visibleSize 为可空（部分驱动/场景取不到），取不到时回退 size
        // final display = await screenRetriever.getPrimaryDisplay();
        // Size screenSize = display.visibleSize ?? display.size;
        // var [width, height] = [355.0, 630.0];
        // if (preferenceSettings.rememberPopupWindowSize && preferenceSettings.fileSenderWindowSize != null) {
        //   final size = preferenceSettings.fileSenderWindowSize!;
        //   width = size.width;
        //   height = size.height;
        // }
        // final maxX = max(screenSize.width - width, 0.0);
        // final maxY = max(screenSize.height - height, 0.0);
        // //限制在屏幕范围内
        // final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        // Map<String, dynamic> args = {
        //   "files": filePaths,
        // };
        // if (multiWindowService.onlineDevicesWindow != null) {
        //   try {
        //     await multiWindowService.showWindowFromHide(
        //       multiWindowService.onlineDevicesWindow!.windowId,
        //       position: [x, y],
        //       args: args,
        //       tag: MultiWindowTag.devices,
        //     );
        //   } catch (e) {
        //     // IPC 失败说明子窗口可能已不可用，重置引用以便下次重新创建窗口
        //     // （否则陈旧引用会卡死该分支，文件弹窗此后打不开）。
        //     logger.warn(tag, "showWindowFromHide failed, will recreate: $e");
        //     multiWindowService.onlineDevicesWindow = null;
        //   }
        //   if (multiWindowService.onlineDevicesWindow != null) {
        //     return;
        //   }
        // }
        // //createWindow里面的参数必须传
        // final title = TranslationKey.syncFile.tr;
        // final window = await DesktopMultiWindow.createWindow(
        //   DesktopMultiWindowArgs.init(
        //     title: title,
        //     tag: MultiWindowTag.devices,
        //     themeMode: await ref.read(appThemeProvider.future),
        //     autoClosePopupOnBlur: _preferenceSettings.autoClosePopupOnBlur,
        //     selfDeviceGuid: _localDeviceInfo.guid,
        //     otherArgs: args,
        //   ).toString(),
        // );
        // multiWindowService.onlineDevicesWindow = window;
        // //setFrame 走 MoveWindow（物理像素，不乘 DPR），位置与尺寸须乘 radio 转物理
        // window
        //   ..setFrame(Offset(x * radio, y * radio) & Size(width * radio, height * radio))
        //   ..setTitle(title)
        //   ..show();
      },
    );
    _hotkeyMap[HotKeyType.fileSender] = key;
  }

  /// 显示主窗口热键
  Future<void> registerShowMainWindow(HotKey key) async {
    await unRegister(HotKeyType.showMainWindows);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        logger.debug(tag, 'ShowMainWindow HotKey Down');
        unawaited(_tray.showWindow());
        //临时让其置顶显示然后再恢复，否则可能被其他应用盖住
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setAlwaysOnTop(false);
      },
    );
    _hotkeyMap[HotKeyType.showMainWindows] = key;
  }

  /// 退出程序热键
  Future<void> registerExitApp(HotKey key) async {
    await unRegister(HotKeyType.exitApp);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        logger.debug(tag, 'ExitApp HotKey Down');
        final notifyId = await _notify.notify(content: TranslationKey.exitAppViaHotKey.tr, key: exitAppNotifyKey);
        if (notifyId != null) {
          await Future.delayed(exitAppNotifyDuration);
          _notify.cancel(exitAppNotifyKey, notifyId);
        }
        unawaited(_tray.exitApp());
      },
    );
    _hotkeyMap[HotKeyType.exitApp] = key;
  }

  /// 注销指定类型的热键
  Future<void> unRegister(HotKeyType type) async {
    var key = _hotkeyMap[type];
    if (key == null) {
      return;
    }
    _hotkeyMap.remove(type);
    await hotKeyManager.unregister(key);
  }

  /// 注销全部热键
  Future<void> unRegisterAll() async {
    _hotkeyMap.clear();
    await hotKeyManager.unregisterAll();
  }

  /// 退出前释放全部热键，并按用户设置恢复 Win+V，避免接管状态在 Explorer 中长期残留。
  Future<void> releaseBeforeExit() async {
    try {
      await unRegisterAll();
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    if (!isWindows) {
      return;
    }
    final hotKeySettings = _hotKeySettings;
    if (!hotKeySettings.takeOverWinV || !hotKeySettings.restoreWinVOnExit) {
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

  /// 启动初始化：先确保 Win+V 接管状态与注册表一致，再按配置注册热键。
  Future<void> _init() async {
    await unRegisterAll();
    await _ensureWinVTakeover();
    final hotKeySettings = _hotKeySettings;
    //接管 Win+V 时历史弹窗固定使用 Win+V
    final historyWindowHotKeys = hotKeySettings.takeOverWinV ? winVHistoryWindowKeys : hotKeySettings.historyWindowHotKeys;
    if (historyWindowHotKeys.isNotEmpty) {
      final hotKey = toSystemHotKey(historyWindowHotKeys);
      await registerHistoryWindow(hotKey);
    }
    if (hotKeySettings.syncFileHotKeys.isNotEmpty) {
      final hotKey = toSystemHotKey(hotKeySettings.syncFileHotKeys);
      await registerFileSync(hotKey);
    }
  }

  /// 接管开关开启但注册表未禁用 Win+V 时写回注册表并重启 Explorer，仅 Windows 生效。
  Future<void> _ensureWinVTakeover() async {
    if (!isWindows) {
      return;
    }
    if (!_hotKeySettings.takeOverWinV) {
      return;
    }
    final disabled = await isWinVDisabled();
    if (!disabled) {
      final changed = await takeOverWinV();
      if (changed) {
        await restartExplorer();
      }
    }
  }

  /// 服务释放时注销全部热键
  Future<void> _dispose() async {
    try {
      await unRegisterAll();
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }
}
