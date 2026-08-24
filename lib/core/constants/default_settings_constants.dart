import 'dart:convert';
import 'dart:io';

import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:flutter/services.dart';

const String defaultWindowSize = '1000x650';

final historyFloatTypes = [HistoryContentType.text.value, HistoryContentType.image.value];

//默认卡片边框颜色
const defaultCardBorderColor = Color.fromARGB(255, 236, 237, 243);

//默认标签规则
String get defaultTagRules => jsonEncode(
  {
    'version': 1,
    'data': [
      {
        'name': TranslationKey.defaultLinkTagName.tr,
        'rule': r'[a-zA-z]+://[^\s]*',
      },
    ],
  },
);

//默认短信规则
String get defaultSmsRules => jsonEncode(
  {
    'version': 0,
    'data': [],
  },
);


//默认历史弹窗快捷键（Ctrl + Alt + H）
final defaultHistoryWindowKeys = '${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.altLeft.usbHidUsage};${PhysicalKeyboardKey.keyH.usbHidUsage}';

//Windows 接管系统剪贴板历史入口后，历史弹窗固定使用 Win + V。
final winVHistoryWindowKeys = '${PhysicalKeyboardKey.metaLeft.usbHidUsage};${PhysicalKeyboardKey.keyV.usbHidUsage}';

//接管系统剪贴板历史入口时在界面展示的固定快捷键。
const winVHotKeyLabel = 'Win+V';

//文件同步快捷键（Ctrl + Shift + C）
final defaultSyncFileHotKeys = '${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyC.usbHidUsage}';

//显示主窗体快捷键（Ctrl + Shift + S）
final defaultShowMainWindowHotKeys = '${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyS.usbHidUsage}';

//退出程序快捷键（Ctrl + Shift + Q）
final defaultExitAppHotKeys = '${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyQ.usbHidUsage}';

// 多选模式退出操作在 tooltip 中展示的快捷键名称。
const selectionExitShortcutLabel = 'Esc';

// 多选模式删除操作在 tooltip 中展示的快捷键名称。
const selectionDeleteShortcutLabel = 'Del';
