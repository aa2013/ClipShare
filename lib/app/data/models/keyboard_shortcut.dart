import 'dart:ui';

import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class KeyboardShortcut {
  /// 修饰键（Ctrl / Shift / Alt / Meta）
  final Set<HotKeyModifier> modifierKeys;

  /// 物理键（A / B / F1 / Enter ...）
  final Set<PhysicalKeyboardKey> physicalKeys;

  /// 触发回调
  final VoidCallback onTrigger;
  final Set<String?> keys = {};

  KeyboardShortcut({
    this.modifierKeys = const {},
    this.physicalKeys = const {},
    required this.onTrigger,
  }) {
    assert(
      modifierKeys.isNotEmpty || physicalKeys.isNotEmpty,
      'KeyboardShortcut must have at least one key',
    );
    keys.addAll(modifierKeys.map((e) => e.label));
    keys.addAll(physicalKeys.map((e) => e.label));
  }
}
