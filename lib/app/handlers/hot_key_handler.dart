import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/services/window_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
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
    var modifyList = modifiers.split(",").map((e) {
      var key = PhysicalKeyboardKey(e.toInt());
      return key.toModify;
    }).toList(growable: true);
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
        clipboardManager.storeCurrentWindowHwnd();
        final appConfig = Get.find<ConfigService>();
        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        final windowId = appConfig.historyWindow?.windowId;
        final isHide = true && multiWindowService.isHideWindow(windowId);
        if (ids.contains(windowId) && !isHide) {
          await multiWindowService.closeWindow(windowId!, windowId, MultiWindowTag.history);
          //偏好为使用相同快捷键关闭，直接结束
          if (appConfig.closeOnSameHotKey) {
            return;
          }
        }
        var posCfg = appConfig.historyDialogPosition;
        var radio = windowManager.getDevicePixelRatio();
        var offset = await screenRetriever.getCursorScreenPoint();
        //存储的位置配置不为空则按配置显示
        if (posCfg != Offset.zero && appConfig.recordHistoryDialogPosition) {
          offset = posCfg;
        }
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器
        Size screenSize = (await screenRetriever.getPrimaryDisplay()).size;
        final [width, height] = [370.0 * radio, 630.0 * radio];
        final maxX = max(screenSize.width - width, 0.0);
        final maxY = max(screenSize.height - height, 0.0);
        //限制在屏幕范围内
        final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        if (appConfig.historyWindow != null) {
          await multiWindowService.showWindowFromHide(
            appConfig.historyWindow!.windowId,
            position: [x, y],
          );
          return;
        }
        //createWindow里面的参数必须传
        final title = TranslationKey.historyRecord.tr;
        final window = await DesktopMultiWindow.createWindow(
          DesktopMultiWindowArgs.init(
            title: title,
            tag: MultiWindowTag.history,
            themeMode: appConfig.appTheme,
          ).toString(),
        );
        appConfig.historyWindow = window;
        window
          ..setFrame(Offset(x, y) & Size(width, height))
          ..setTitle(title)
          ..show();
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
          multiWindowService.closeWindow(windowId!, windowId, MultiWindowTag.devices);
          //偏好为使用相同快捷键关闭，直接结束
          if (appConfig.closeOnSameHotKey) {
            return;
          }
        }
        var radio = windowManager.getDevicePixelRatio();
        var offset = await screenRetriever.getCursorScreenPoint();
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器
        Size screenSize = (await screenRetriever.getPrimaryDisplay()).size;
        final [width, height] = [355.0 * radio, 630.0 * radio];
        final maxX = max(screenSize.width - width, 0.0);
        final maxY = max(screenSize.height - height, 0.0);
        //限制在屏幕范围内
        final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        Map<String, dynamic> args = {
          "files": filePaths,
        };
        if (appConfig.onlineDevicesWindow != null) {
          await multiWindowService.showWindowFromHide(
            appConfig.onlineDevicesWindow!.windowId,
            position: [x, y],
            args: args,
          );
          return;
        }

        //createWindow里面的参数必须传
        final title = TranslationKey.syncFile.tr;
        final window = await DesktopMultiWindow.createWindow(
          DesktopMultiWindowArgs.init(
            title: title,
            tag: MultiWindowTag.devices,
            themeMode: appConfig.appTheme,
            otherArgs: args,
          ).toString(),
        );
        appConfig.onlineDevicesWindow = window;
        window
          ..setFrame(Offset(x, y) & Size(width, height))
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
        Log.debug(tag, "ShowMainWindow HotKey Down");
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
        Log.debug(tag, "ExitApp HotKey Down");
        Global.notify(content: TranslationKey.exitAppViaHotKey.tr);
        final trayService = Get.find<TrayService>();
        trayService.clickExitAppItem();
      },
    );
    _hotkeyMap[HotKeyType.exitApp] = key;
  }

  static Future<void> unRegister(HotKeyType type) async {
    if (_hotkeyMap[type] == null) return;
    await hotKeyManager.unregister(_hotkeyMap[type]!);
    _hotkeyMap.remove(type);
  }

  static Future<void> unRegisterAll() async {
    _hotkeyMap.clear();
    await hotKeyManager.unregisterAll();
  }
}
