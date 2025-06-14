import 'dart:io';
import 'dart:math';

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
  static const tag = "AppHotKeyHandler";
  static const historyWindow = "HistoryWindow";
  static const fileSync = "fileSync";
  static final Map<String, HotKey> _map = {};

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

  /// 历史弹窗
  static Future<void> registerHistoryWindow(HotKey key) async {
    String hotkeyName = historyWindow;
    await unRegister(hotkeyName);
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
        var windowId = appConfig.onlineDevicesWindow?.windowId;
        if (ids.contains(windowId)) {
          // await appConfig.historyWindow?.close();
          await multiWindowService.closeWindow(windowId!, MultiWindowTag.history);
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
    _map[hotkeyName] = key;
  }

  ///同步文件
  static Future<void> registerFileSync(HotKey key) async {
    String hotkeyName = fileSync;
    await unRegister(hotkeyName);
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
        var windowId = appConfig.onlineDevicesWindow?.windowId;
        //只允许弹窗一次
        if (ids.contains(windowId)) {
          // await appConfig.onlineDevicesWindow?.close();
          multiWindowService.closeWindow(windowId!, MultiWindowTag.devices);
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
    _map[hotkeyName] = key;
  }

  static Future<void> unRegister(String name) async {
    if (_map[name] == null) return;
    await hotKeyManager.unregister(_map[name]!);
    _map.remove(name);
  }

  static Future<void> unRegisterAll() async {
    _map.clear();
    await hotKeyManager.unregisterAll();
  }
}
