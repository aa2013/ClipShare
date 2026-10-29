import 'package:clipshare/shared/extensions/keyboard_key_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// 解析"修饰键码,修饰键码;主键码"格式的热键串为系统级热键。
///
/// [keyCodes] 各码值为 PhysicalKeyboardKey.usbHidUsage 的十进制字符串。
HotKey toSystemHotKey(String keyCodes) {
  var [modifiers, key] = keyCodes.split(';');
  var modifyList = modifiers
      .split(',')
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
