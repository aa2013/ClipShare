import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/shared/extensions/keyboard_key_extension.dart';
import 'package:clipshare/shared/utils/hotkey_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

void main() {
  group('toSystemHotKey', () {
    test('parses single modifier and main key into a system hotkey', () {
      final keyCodes = '${PhysicalKeyboardKey.controlLeft.usbHidUsage};${PhysicalKeyboardKey.keyH.usbHidUsage}';
      final hotKey = toSystemHotKey(keyCodes);
      expect(hotKey.key, PhysicalKeyboardKey.keyH);
      expect(hotKey.modifiers, contains(HotKeyModifier.control));
      expect(hotKey.modifiers?.length, 1);
      expect(hotKey.scope, HotKeyScope.system);
    });

    test('parses multiple modifiers preserving input order', () {
      final modifiers = [
        PhysicalKeyboardKey.controlLeft.usbHidUsage,
        PhysicalKeyboardKey.shiftLeft.usbHidUsage,
      ].join(',');
      final keyCodes = '$modifiers;${PhysicalKeyboardKey.keyC.usbHidUsage}';
      final hotKey = toSystemHotKey(keyCodes);
      expect(hotKey.desc, 'Ctrl + Shift + C');
    });

    test('parses the fixed Win+V history window hotkey', () {
      final hotKey = toSystemHotKey(winVHistoryWindowKeys);
      expect(hotKey.desc, 'Meta + V');
    });

    test('parses the default history window hotkey', () {
      final hotKey = toSystemHotKey(defaultHistoryWindowKeys);
      expect(hotKey.desc, 'Ctrl + Alt + H');
    });
  });
}
