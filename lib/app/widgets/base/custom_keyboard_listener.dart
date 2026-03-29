import 'package:clipshare/app/data/models/keyboard_shortcut.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CustomKeyboardListener extends StatefulWidget {
  final Widget child;
  final List<KeyboardShortcut> shortcuts;
  final FocusNode focusNode;

  const CustomKeyboardListener({
    super.key,
    required this.child,
    required this.shortcuts,
    required this.focusNode,
  });

  @override
  State<StatefulWidget> createState() {
    return _CustomKeyboardListenerState();
  }
}

class _CustomKeyboardListenerState extends State<CustomKeyboardListener> {
  final pressedKeys = <String?>{};

  void onKeyEvent(KeyEvent event) {
    final key = event.physicalKey;
    if (event is KeyDownEvent) {
      if (key.isModify) {
        pressedKeys.add(key.toModify.label);
      } else {
        pressedKeys.add(key.label);
      }
      //判断是否符合按键
      checkShortcuts();
    } else if (event is KeyUpEvent) {
      if (key.isModify) {
        pressedKeys.remove(key.toModify.label);
      } else {
        pressedKeys.remove(key.label);
      }
    }
  }

  void checkShortcuts() {
    for (final shortcut in widget.shortcuts) {
      final set = pressedKeys.intersection(shortcut.keys);
      if (set.length == shortcut.keys.length) {
        shortcut.onTrigger();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: widget.focusNode,
      onKeyEvent: onKeyEvent,
      child: widget.child,
    );
  }
}
