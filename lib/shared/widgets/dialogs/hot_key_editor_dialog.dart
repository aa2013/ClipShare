import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/hot_key_type.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/hotkey_util.dart';
import 'package:clipshare/shared/widgets/hotkey/hot_key_editor.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// 热键编辑对话框：录入新组合键后需二次确认，[onDone] 回调转换后的系统热键与热键码串
class HotKeyEditorDialog extends StatefulWidget {
  /// 正在编辑的热键类型
  final HotKeyType hotKeyType;

  /// 初始展示的热键描述文本
  final String initContent;

  /// 是否强制要求包含修饰键
  final bool requiredModifierKey;

  /// 是否允许清除已配置的热键
  final bool clearable;

  /// 确认修改回调
  final void Function(HotKey key, String keyCodes) onDone;

  /// 清除回调
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
  var verifyErrorTips = '';

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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: () {
                      final verify = verifyInput();
                      if (verify) {
                        confirmModify();
                      } else {
                        dialogManager.tips(
                          context,
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

  /// 校验通过后弹出二次确认框，确认时转换热键并回调结果。
  void confirmModify() {
    final keyCodes = hotkeyController.keyCodes;
    final showText = hotkeyController.keysDesc;
    dialogManager.tips(
      context,
      text: TranslationKey.hotKeySettingsSaveKeysDialogText.trParams({'keys': showText}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () {
            final hotkey = toSystemHotKey(keyCodes);
            widget.onDone(hotkey, keyCodes);
            //确认提示框自动关闭后再关闭编辑框自身
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// 校验录入是否合法：与原值相同直接放行；否则必须有主键且（要求时）带修饰键。
  bool verifyInput() {
    final showText = hotkeyController.keysDesc;
    final modifiers = hotkeyController.modifiers ?? <HotKeyModifier>[];
    final key = hotkeyController.keyboardKey;
    if (showText == widget.initContent) {
      return true;
    }
    if ((widget.requiredModifierKey && modifiers.isEmpty) || key == null) {
      verifyErrorTips = TranslationKey.hotKeySettingsCombinationInvalidText.tr;
      return false;
    }
    return true;
  }
}
