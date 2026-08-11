import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/data/enums/multi_window_config.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/desktop_multi_window_args.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class AppHotKeyHandler {
  AppHotKeyHandler._private();

  static const tag = "AppHotKeyHandler";
  static final Map<HotKeyType, HotKey> _hotkeyMap = {};

  static HotKey toSystemHotKey(String keyCodes) {
    var [modifiers, key] = keyCodes.split(";");
    var modifyList = modifiers
        .split(",")
        .map((e) {
          var key = PhysicalKeyboardKey(e.toInt());
          return key.toModify;
        })
        .toList(growable: true);
    return HotKey(
      key: PhysicalKeyboardKey(key.toInt()),
      modifiers: modifyList,
      scope: HotKeyScope.system,
    );
  }

  static HotKey? getByType(HotKeyType type) {
    return _hotkeyMap[type];
  }

  /// 历史弹窗
  static Future<void> registerHistoryWindow(HotKey key) async {
    await unRegister(HotKeyType.historyWindow);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        final multiWindowService = Get.find<MultiWindowChannelService>();
        // clipboardManager.storeCurrentWindowHwnd();
        final appConfig = Get.find<ConfigService>();
        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        final windowId = appConfig.historyWindow?.windowId;
        final isHide = multiWindowService.isHideWindow(windowId);
        if (ids.contains(windowId) && !isHide) {
          // 用 hideChildWindow 替代 closeWindow：closeWindow 里的 windowManager.hide()
          // 在主窗口 isolate 执行会隐藏主窗口（而非弹窗），导致按 Win+V 时主界面被关闭。
          // hideChildWindow 只发 IPC 让子窗口自隐藏，主窗口不受影响。
          await multiWindowService.hideChildWindow(windowId!, MultiWindowTag.history).catchError((err) {
            logger.warn(tag, "hideChildWindow failed: $err");
          });
          //偏好为使用相同快捷键关闭，直接结束
          if (appConfig.closeOnSameHotKey) {
            return;
          }
        }
        var posCfg = appConfig.historyDialogPosition;
        // 每次按 Win+V 打开弹窗前重置置顶状态：置顶只在当次显示有效（下次打开不置顶）。
        // 此前依赖子窗口 IPC 回传清零，回传前存在"点击外部不关"的窗口期。
        appConfig.historyPinned.value = false;
        var radio = windowManager.getDevicePixelRatio();
        var offset = await screenRetriever.getCursorScreenPoint();
        //存储的位置配置不为空则按配置显示
        if (posCfg != Offset.zero && appConfig.recordHistoryDialogPosition) {
          offset = posCfg;
        }
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器。
        //已知限制：混合 DPI（主屏 150%+副屏 100%）下 getCursorScreenPoint 除的是
        //Flutter view 的 DPR 而非光标所在显示器（screen_retriever 上游行为），
        //换 getDisplayList() 也无法单独修复——多屏垂直判断可能不准，勿误以为是本处 bug。
        //screenRetriever 的鼠标坐标/屏幕尺寸均为逻辑像素，位置计算用逻辑像素
        //（原代码乘 devicePixelRatio 会放大尺寸，导致上方空间误判放不下）
        //visibleSize 为可空（部分驱动/场景取不到），取不到时回退 size
        final display = await screenRetriever.getPrimaryDisplay();
        Size screenSize = display.visibleSize ?? display.size;
        var [width, height] = [370.0, 630.0];
        if (appConfig.rememberPopupWindowSize && appConfig.historyWindowSize != null) {
          final size = appConfig.historyWindowSize!;
          width = size.width;
          height = size.height;
        }
        final maxX = max(screenSize.width - width, 0.0);
        final maxY = max(screenSize.height - height, 0.0);
        //弹窗与光标/输入框的垂直间隔：弹上方贴紧光标上方，弹下方贴紧光标下方
        const gapAbove = 15.0;
        const gapBelow = 15.0;
        final x = min(maxX, offset.dx);
        final double y;
        if (posCfg != Offset.zero && appConfig.recordHistoryDialogPosition) {
          //记忆位置：原样使用（用户已手动调整过弹窗位置）
          y = min(maxY, offset.dy);
        } else {
          //跟随鼠标：优先弹在光标/输入框上方（避免遮挡输入框与光标），
          //上方空间不足（弹窗较高时普通输入框位置也放不下）才弹到下方
          y = offset.dy - height - gapAbove >= 0
              ? offset.dy - height - gapAbove
              : min(maxY, offset.dy + gapBelow);
        }
        if (appConfig.historyWindow != null) {
          try {
            await multiWindowService.showWindowFromHide(
              appConfig.historyWindow!.windowId,
              position: [x, y],
              tag: MultiWindowTag.history,
            );
          } catch (e) {
            // IPC 失败说明子窗口可能已不可用，重置引用以便下次重新创建窗口。
            logger.warn(tag, "showWindowFromHide failed, will recreate: $e");
            appConfig.historyWindow = null;
          }
          if (appConfig.historyWindow != null) {
            return;
          }
        }
        //createWindow里面的参数必须传
        final title = TranslationKey.historyRecord.tr;
        final window = await DesktopMultiWindow.createWindow(
          DesktopMultiWindowArgs.init(
            title: title,
            tag: MultiWindowTag.history,
            themeMode: appConfig.appTheme,
            autoClosePopupOnBlur: appConfig.autoClosePopupOnBlur,
            selfDeviceGuid: appConfig.device.guid,
            otherArgs: {MultiWindowConfig.clickToPaste.name: appConfig.clickToPaste},
          ).toString(),
        );
        appConfig.historyWindow = window;
        //desktop_multi_window 的 setFrame 走 MoveWindow（物理像素，不乘 DPR），
        //位置与尺寸须乘 radio 转物理；而 showWindowFromHide 的 position 走
        //window_manager（逻辑像素），故位置计算用逻辑、setFrame 单独转物理。
        window
          ..setFrame(Offset(x * radio, y * radio) & Size(width * radio, height * radio))
          ..setTitle(title)
          ..show();
        //首次创建后补开启 Raw Input 监听（showWindowFromHide 才有 enable，
        //createWindow 路径没有会导致本机重启后第一个弹窗点击外部不关闭）。
        //放在 setFrame/setTitle/show 之后：把这几步耗时从 500ms 宽限期预算里省出来。
        multiWindowService.removeHideWindow(window.windowId, MultiWindowTag.history);
      },
    );
    _hotkeyMap[HotKeyType.historyWindow] = key;
  }

  ///同步文件
  static Future<void> registerFileSync(HotKey key) async {
    await unRegister(HotKeyType.fileSender);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        final appConfig = Get.find<ConfigService>();
        final multiWindowService = Get.find<MultiWindowChannelService>();

        ///快捷键事件
        final res = await clipboardManager.getSelectedFiles();
        final files = res.list;
        List<String> filePaths = List.empty(growable: true);
        for (var filePath in files) {
          FileSystemEntityType type = await FileSystemEntity.type(filePath);
          switch (type) {
            case FileSystemEntityType.file:
              filePaths.add(filePath);
              break;
            default:
          }
        }

        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        final windowId = appConfig.onlineDevicesWindow?.windowId;
        final isHide = multiWindowService.isHideWindow(windowId);
        //只允许弹窗一次
        if (ids.contains(windowId) && !isHide) {
          // 同 history：主窗口 isolate 调 closeWindow 会隐藏主窗口，改用 hideChildWindow
          await multiWindowService.hideChildWindow(windowId!, MultiWindowTag.devices).catchError((err) {
            logger.warn(tag, "hideChildWindow failed: $err");
          });
          //偏好为使用相同快捷键关闭，直接结束
          if (appConfig.closeOnSameHotKey) {
            return;
          }
        }
        var radio = windowManager.getDevicePixelRatio();
        var offset = await screenRetriever.getCursorScreenPoint();
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器。
        //混合 DPI 限制同 history 分支（getCursorScreenPoint 除的是 Flutter view 的 DPR）。
        //screenRetriever 的鼠标坐标/屏幕尺寸均为逻辑像素，位置计算用逻辑像素
        //（与 history 同款修复：原乘 devicePixelRatio 会把尺寸放大，首次创建位置偏左上）
        //visibleSize 为可空（部分驱动/场景取不到），取不到时回退 size
        final display = await screenRetriever.getPrimaryDisplay();
        Size screenSize = display.visibleSize ?? display.size;
        var [width, height] = [355.0, 630.0];
        if (appConfig.rememberPopupWindowSize && appConfig.fileSenderWindowSize != null) {
          final size = appConfig.fileSenderWindowSize!;
          width = size.width;
          height = size.height;
        }
        final maxX = max(screenSize.width - width, 0.0);
        final maxY = max(screenSize.height - height, 0.0);
        //限制在屏幕范围内
        final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        Map<String, dynamic> args = {
          "files": filePaths,
        };
        if (appConfig.onlineDevicesWindow != null) {
          try {
            await multiWindowService.showWindowFromHide(
              appConfig.onlineDevicesWindow!.windowId,
              position: [x, y],
              args: args,
              tag: MultiWindowTag.devices,
            );
          } catch (e) {
            // IPC 失败说明子窗口可能已不可用，重置引用以便下次重新创建窗口
            // （否则陈旧引用会卡死该分支，文件弹窗此后打不开）。
            logger.warn(tag, "showWindowFromHide failed, will recreate: $e");
            appConfig.onlineDevicesWindow = null;
          }
          if (appConfig.onlineDevicesWindow != null) {
            return;
          }
        }

        //createWindow里面的参数必须传
        final title = TranslationKey.syncFile.tr;
        final window = await DesktopMultiWindow.createWindow(
          DesktopMultiWindowArgs.init(
            title: title,
            tag: MultiWindowTag.devices,
            themeMode: appConfig.appTheme,
            autoClosePopupOnBlur: appConfig.autoClosePopupOnBlur,
            selfDeviceGuid: appConfig.device.guid,
            otherArgs: args,
          ).toString(),
        );
        appConfig.onlineDevicesWindow = window;
        //setFrame 走 MoveWindow（物理像素，不乘 DPR），位置与尺寸须乘 radio 转物理
        window
          ..setFrame(Offset(x * radio, y * radio) & Size(width * radio, height * radio))
          ..setTitle(title)
          ..show();
      },
    );
    _hotkeyMap[HotKeyType.fileSender] = key;
  }

  ///显示主窗口
  static Future<void> registerShowMainWindow(HotKey key) async {
    await unRegister(HotKeyType.showMainWindows);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        logger.debug(tag, "ShowMainWindow HotKey Down");
        final trayService = Get.find<TrayService>();
        trayService.clickShowWindowItem();
        //临时让其置顶显示然后再恢复，否则可能被其他应用盖住
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setAlwaysOnTop(false);
      },
    );
    _hotkeyMap[HotKeyType.showMainWindows] = key;
  }

  ///退出程序
  static Future<void> registerExitApp(HotKey key) async {
    await unRegister(HotKeyType.exitApp);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        logger.debug(tag, "ExitApp HotKey Down");
        const notifyKey = "appExit";
        final notifyId = await NotifyUtil.notify(content: TranslationKey.exitAppViaHotKey.tr, key: notifyKey);
        if (notifyId != null) {
          Future.delayed(2.s, () {
            NotifyUtil.cancel(notifyKey, notifyId);
          });
        }
        final trayService = Get.find<TrayService>();
        trayService.clickExitAppItem();
      },
    );
    _hotkeyMap[HotKeyType.exitApp] = key;
  }

  static Future<void> unRegister(HotKeyType type) async {
    var key = _hotkeyMap[type];
    if (key == null) return;
    _hotkeyMap.remove(type);
    await hotKeyManager.unregister(key);
  }

  static Future<void> unRegisterAll() async {
    _hotkeyMap.clear();
    await hotKeyManager.unregisterAll();
  }
}
