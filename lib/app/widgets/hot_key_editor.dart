import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotKeyEditorController {
  List<HotKeyModifier>? modifiers;
  PhysicalKeyboardKey? keyboardKey;
  String keysDesc = "";
  String keyCodes = "";
}

class HotKeyEditor extends StatefulWidget {
  final String hotKey;
  final HotKeyEditorController controller;

  const HotKeyEditor({
    super.key,
    required this.hotKey,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() {
    return _HotKeyEditorState();
  }
}

class _HotKeyEditorState extends State<HotKeyEditor> {
  final _editor = TextEditingController();
  final _focusNode = FocusNode();
  PhysicalKeyboardKey? _key;
  final List<HotKeyModifier> _modifiers = [];
  List<HotKeyModifier> customOrder = [
    HotKeyModifier.control,
    HotKeyModifier.alt,
    HotKeyModifier.shift,
    HotKeyModifier.fn,
    HotKeyModifier.capsLock,
    HotKeyModifier.meta,
  ];
  var _keyCodes = "";

  @override
  void initState() {
    if (widget.hotKey.trim().isNotEmpty) {
      _editor.text = widget.hotKey;
    }
    super.initState();
  }

  void updateText() {
    var descList = _modifiers.map((e) => PhysicalKeyboardKeyExt.toModifyString(e)).toList(growable: true);
    //将modifiers以逗号分隔，然后以分号结尾
    _keyCodes = "${_modifiers.map((e) => e.physicalKeys[0].usbHidUsage).toList().join(',')};";
    if (_key != null) {
      _keyCodes += _key!.usbHidUsage.toString();
      descList.add(_key!.simpleLabel!);
    }
    _editor.text = descList.join(" + ");
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        var isKeyUp = event is KeyUpEvent;
        var key = event.physicalKey;
        if (key.isModify) {
          //判断是否包含
          var isInclude = false;
          for (var saved in _modifiers) {
            if (saved.physicalKeys.contains(key)) {
              isInclude = true;
              break;
            }
          }
          if (isInclude && !isKeyUp && _modifiers.length != 1 && _key != null) {
            _modifiers.clear();
            _modifiers.add(key.toModify);
            _key = null;
          } else if (!isInclude) {
            _modifiers.add(key.toModify);
            _modifiers.sort((a, b) {
              var i = customOrder.indexOf(a);
              var j = customOrder.indexOf(b);
              return i.compareTo(j);
            });
          }
        } else {
          if (key.label != null) {
            _key = key;
          }
        }
        updateText();
      },
      child: TextField(
        readOnly: true,
        controller: _editor,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: TranslationKey.pleaseEnterHotKey.tr,
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        onTap: () {
          setState(() {
            _modifiers.clear();
            _key = null;
          });
        },
        onTapOutside: (event) {
          setState(() {
            _focusNode.unfocus();
            widget.controller.modifiers = _modifiers;
            widget.controller.keyboardKey = _key;
            widget.controller.keysDesc = _editor.text;
            widget.controller.keyCodes = _keyCodes;
          });
        },
      ),
    );
  }
}
