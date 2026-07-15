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
  late final String signature;

  /// 创建页面内快捷键配置。
  ///
  /// [signature] 只用于快捷键匹配和重复注册判断；修饰键会按固定顺序归一化，
  /// 因此左右 Ctrl / Alt / Shift / Meta 会被视为同一个业务快捷键。
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
    signature = buildSignature(
      modifierKeys: modifierKeys,
      physicalKeys: physicalKeys,
    );
  }

  /// 生成稳定的快捷键签名，避免按键顺序或左右修饰键差异影响匹配结果。
  static String buildSignature({
    Set<HotKeyModifier> modifierKeys = const {},
    Set<PhysicalKeyboardKey> physicalKeys = const {},
  }) {
    const modifierOrder = PhysicalKeyboardKeyExt.modifierOrder;
    final normalizedModifiers = modifierKeys.toList(growable: false)
      ..sort((a, b) => modifierOrder.indexOf(a).compareTo(modifierOrder.indexOf(b)));
    final normalizedPhysicalKeys = physicalKeys
        .map((key) => key.label)
        .whereType<String>()
        .toList(growable: false)
      ..sort();
    return [
      ...normalizedModifiers.map((key) => key.label),
      ...normalizedPhysicalKeys,
    ].join('+');
  }
}
