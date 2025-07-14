import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/hot_key_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotKeyEditorDialog extends StatefulWidget {
  final HotKeyType hotKeyType;
  final String initContent;
  final bool requiredModifierKey;
  final bool clearable;
  final void Function(HotKey key, String keyCodes) onDone;
  final void Function()? onClear;

  const HotKeyEditorDialog({
    super.key,
    required this.hotKeyType,
    required this.initContent,
    required this.onDone,
    this.onClear,
    this.requiredModifierKey = true,
    this.clearable = false,
  });

  @override
  State<StatefulWidget> createState() => _HotKeyEditorDialogState();
}

class _HotKeyEditorDialogState extends State<HotKeyEditorDialog> {
  final hotkeyController = HotKeyEditorController();
  var verifyErrorTips = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.keyboard_alt_outlined),
          const SizedBox(width: 5),
          Text(TranslationKey.modify.tr + TranslationKey.hotKeySettingsGroupName.tr),
        ],
      ),
      content: HotKeyEditor(hotKey: widget.initContent, controller: hotkeyController),
      actions: [
        Row(
          children: [
            Visibility(
              visible: widget.clearable,
              child: Tooltip(
                message: TranslationKey.clear.tr,
                child: TextButton(
                  onPressed: () {
                    widget.onClear?.call();
                  },
                  child: Text(TranslationKey.clear.tr),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Get.back,
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: () {
                      final verify = verifyInput();
                      if (verify) {
                        final keyCodes = hotkeyController.keyCodes;
                        final showText = hotkeyController.keysDesc;
                        Global.showTipsDialog(
                          context: context,
                          text: TranslationKey.hotKeySettingsSaveKeysDialogText.trParams({"keys": showText}),
                          showCancel: true,
                          onOk: () {
                            var hotkey = AppHotKeyHandler.toSystemHotKey(keyCodes);
                            widget.onDone(hotkey, keyCodes);
                            Get.back();
                          },
                        );
                      } else {
                        Global.showTipsDialog(
                          context: context,
                          text: verifyErrorTips,
                        );
                      }
                    },
                    child: Text(TranslationKey.dialogConfirmText.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool verifyInput() {
    final showText = hotkeyController.keysDesc;
    final modifiers = hotkeyController.modifiers ?? <HotKeyModifier>[];
    final key = hotkeyController.keyboardKey;
    if (showText == widget.initContent) return true;
    if ((widget.requiredModifierKey && modifiers.isEmpty) || key == null) {
      verifyErrorTips = TranslationKey.hotKeySettingsCombinationInvalidText.tr;
      return false;
    } else {
      return true;
    }
  }
}
