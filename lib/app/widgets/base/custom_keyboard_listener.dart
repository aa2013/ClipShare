import 'package:clipshare/app/data/models/keyboard_shortcut.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class CustomKeyboardListener extends StatefulWidget {
  final Widget child;
  final List<KeyboardShortcut> shortcuts;
  final FocusNode? focusNode;

  const CustomKeyboardListener({
    super.key,
    required this.child,
    required this.shortcuts,
    this.focusNode,
  });

  @override
  State<StatefulWidget> createState() {
    return _CustomKeyboardListenerState();
  }
}

class _CustomKeyboardListenerState extends State<CustomKeyboardListener> {
  static const _logTag = 'CustomKeyboardListener';
  final _pressedModifierKeys = <HotKeyModifier>{};
  final _pressedPhysicalKeys = <PhysicalKeyboardKey>{};
  final _shortcuts = <String, KeyboardShortcut>{};
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _resetInternalFocusNode();
    _refreshShortcuts();
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  @override
  void didUpdateWidget(covariant CustomKeyboardListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcuts != widget.shortcuts) {
      _refreshShortcuts();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _resetInternalFocusNode();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    _pressedModifierKeys.clear();
    _pressedPhysicalKeys.clear();
    _shortcuts.clear();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  /// 仅释放组件内部创建的焦点节点，避免误释放调用方传入的 FocusNode。
  void _resetInternalFocusNode() {
    if (widget.focusNode == null) {
      _internalFocusNode ??= FocusNode();
      return;
    }
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
  }

  /// 刷新快捷键注册表；重复签名代表同一个业务快捷键，后注册项覆盖先注册项。
  void _refreshShortcuts() {
    _shortcuts.clear();
    for (final shortcut in widget.shortcuts) {
      final signature = shortcut.signature;
      if (_shortcuts.containsKey(signature)) {
        logger.warn(_logTag, '快捷键重复注册：$signature，已使用最后一个配置覆盖');
      }
      _shortcuts[signature] = shortcut;
    }
  }

  /// 响应按键事件，并将左右修饰键归一为 HotKeyModifier 后再匹配快捷键。
  void onKeyEvent(KeyEvent event) {
    final key = event.physicalKey;
    if (event is KeyDownEvent) {
      if (key.isModify) {
        _pressedModifierKeys.add(key.toModify);
      } else {
        _pressedPhysicalKeys.add(key);
      }
      checkShortcuts();
    } else if (event is KeyUpEvent) {
      if (key.isModify) {
        _pressedModifierKeys.remove(key.toModify);
      } else {
        _pressedPhysicalKeys.remove(key);
      }
    }
  }

  /// 在硬件键盘层监听页面快捷键，避免 TextField 等输入控件获得焦点后吞掉 Esc。
  bool _handleHardwareKeyEvent(KeyEvent event) {
    onKeyEvent(event);
    return false;
  }

  /// 使用完整签名精确匹配，避免 Ctrl+Esc 误触发仅配置 Esc 的回调。
  void checkShortcuts() {
    final signature = KeyboardShortcut.buildSignature(
      modifierKeys: _pressedModifierKeys,
      physicalKeys: _pressedPhysicalKeys,
    );
    _shortcuts[signature]?.onTrigger();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: true,
      child: widget.child,
    );
  }
}
