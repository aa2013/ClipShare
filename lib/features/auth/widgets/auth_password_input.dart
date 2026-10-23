import 'dart:math';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:clipshare/shared/extensions/list_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// 应用密码输入组件
///
/// [onFinished] 输入完成时的校验回调，[first] 为首次输入，[second] 为二次确认输入；
/// [onOk] 校验通过后的确认回调，返回 true 时组件自行关闭所在路由；
/// [again] 开启二次输入确认模式（用于设置密码）；
/// [showCancelBtn] 是否显示取消按钮（仅桌面端显示）。
class AuthPasswordInput extends StatefulWidget {
  final bool Function(String first, String? second) onFinished;
  final void Function()? onError;
  final bool Function(String input) onOk;
  final String tipText;
  final String againText;
  final String errorText;
  final bool again;
  final bool showCancelBtn;

  AuthPasswordInput({
    super.key,
    required this.onFinished,
    required this.onOk,
    String? tipText,
    String? againText,
    String? errorText,
    this.again = false,
    this.onError,
    this.showCancelBtn = false,
  })  : tipText = tipText ?? TranslationKey.inputPassword.tr,
        againText = againText ?? TranslationKey.inputAgain.tr,
        errorText = errorText ?? TranslationKey.inputErrorAndAgain.tr;

  @override
  State<StatefulWidget> createState() {
    return _AuthPasswordInputState();
  }
}

class _AuthPasswordInputState extends State<AuthPasswordInput> {
  static const maxLen = 4;
  static const separate = 10.0;
  static const separateHeight = SizedBox(height: separate);
  static const separateWidth = SizedBox(width: separate);
  static const rowAlign = MainAxisAlignment.center;
  static const deleteKeys = [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace];
  static const inputDotWidth = 15.0;
  var _first = '';
  String _second = '';
  var secondInput = false;
  var _error = false;

  String get currentInput => secondInput && widget.again ? _second : _first;

  String get _currentShowText => secondInput ? widget.againText : widget.tipText;
  static const deleteIcon = Icon(
    Icons.backspace_outlined,
    color: Colors.orange,
    size: 45,
  );

  void setCurrentInput(String input) {
    if (secondInput && widget.again) {
      _second = input;
    } else {
      _first = input;
    }
  }

  void onNumberInput(int i) {
    HapticFeedback.mediumImpact();
    if (currentInput.length >= maxLen) {
      return;
    }
    setCurrentInput('$currentInput$i');
    if (currentInput.length == maxLen) {
      //不需要重复输入或是第二次输入完成
      if (!widget.again || (widget.again && secondInput)) {
        _error = !widget.onFinished.call(_first, secondInput ? _second : null);
        if (_error) {
          Future.delayed(100.ms, () {
            if (!mounted) {
              return;
            }
            setCurrentInput('');
            if (widget.again) {
              //如果是重复输入模式，清除第一次输入
              secondInput = false;
              setCurrentInput('');
            }
            setState(() {});
            //连续振动
            for (var i = 0; i < 4; i++) {
              HapticFeedback.mediumImpact();
            }
            widget.onError?.call();
          });
        } else {
          if (widget.onOk.call(currentInput)) {
            context.pop();
          }
        }
      } else {
        //需要重复输入且第一次输入完成
        Future.delayed(
          200.ms,
          () {
            if (!mounted) {
              return;
            }
            secondInput = true;
            setState(() {});
          },
        );
      }
    } else {
      _error = false;
    }
    setState(() {});
  }

  void onNumberDelete() {
    HapticFeedback.mediumImpact();
    if (currentInput.isEmpty) return;
    setCurrentInput(currentInput.substring(0, currentInput.length - 1));
    setState(() {});
  }

  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    focusNode.dispose();
    super.dispose();
  }

  /// 物理键盘输入处理：数字键 0-9（含小键盘）与退格/删除键
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    final key = event.logicalKey;
    const digit0 = LogicalKeyboardKey.digit0;
    const numPad0 = LogicalKeyboardKey.numpad0;
    var keyIdOffset = key.keyId - digit0.keyId;
    // 检查是否是数字键(0-9)
    if ((keyIdOffset = key.keyId - digit0.keyId).between(0, 9)) {
      onNumberInput(keyIdOffset);
    } else if ((keyIdOffset = key.keyId - numPad0.keyId).between(0, 9)) {
      onNumberInput(keyIdOffset);
    }
    // 检查是否是退格或删除键
    else if (deleteKeys.contains(key)) {
      onNumberDelete();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final numberContainerBg = currentTheme.cardTheme.color ?? currentTheme.colorScheme.surface;
    return KeyboardListener(
      focusNode: focusNode,
      child: SafeArea(
        maintainBottomViewPadding: isAndroid,
        child: Material(
          color: currentTheme.scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: Column(
                  children: [
                    Image.asset(
                      logoPngPath,
                      width: 140,
                      fit: BoxFit.fitWidth,
                    ),
                    Text(
                      _error ? widget.errorText : _currentShowText,
                      style: TextStyle(
                        fontSize: 18,
                        color: _error ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (var i = 0; i < 4; i++)
                            AnimatedContainer(
                              width: inputDotWidth,
                              height: inputDotWidth,
                              duration: 200.ms,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(inputDotWidth / 2),
                                color: currentInput.length > i ? Colors.blue : Colors.transparent,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    var maxWidth = constraints.maxWidth / 3 * 0.8;
                    var maxHeight = (constraints.maxHeight - separate * 5) / 4;
                    final edgeLen = min(maxHeight, maxWidth);
                    final radius = edgeLen / 2;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (var i = 1; i <= 3; i++)
                          Row(
                            mainAxisAlignment: rowAlign,
                            children: [
                              for (var j = 1; j <= 3; j++)
                                Ink(
                                  decoration: BoxDecoration(
                                    //颜色放外面的Ink，否则水波纹被遮挡
                                    color: numberContainerBg,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                    child: AnimatedContainer(
                                      width: edgeLen,
                                      height: edgeLen,
                                      duration: 200.ms,
                                      child: Center(
                                        child: Text(
                                          '${(i - 1) * 3 + j}',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () => onNumberInput((i - 1) * 3 + j),
                                  ),
                                ),
                            ].cast<Widget>().separateWith(separateWidth),
                          ),
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: rowAlign,
                              children: [
                                SizedBox(
                                  width: edgeLen,
                                  height: edgeLen,
                                ),
                                Ink(
                                  decoration: BoxDecoration(
                                    //颜色放外面的Ink，否则水波纹被遮挡
                                    color: numberContainerBg,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                    child: AnimatedContainer(
                                      width: edgeLen,
                                      height: edgeLen,
                                      duration: 200.ms,
                                      child: const Center(
                                        child: Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () => onNumberInput(0),
                                  ),
                                ),
                                Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                  ),
                                  child: InkWell(
                                    splashColor: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(radius),
                                    ),
                                    onTap: onNumberDelete,
                                    child: AnimatedContainer(
                                      width: edgeLen,
                                      height: edgeLen,
                                      duration: 200.ms,
                                      child: const Center(
                                        child: deleteIcon,
                                      ),
                                    ),
                                  ),
                                ),
                              ].cast<Widget>().separateWith(separateWidth),
                            ),
                            if (widget.showCancelBtn && isDesktop)
                              Positioned(
                                right: 30,
                                bottom: 15,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(TranslationKey.dialogCancelText.tr),
                                ),
                              ),
                          ],
                        ),
                      ].cast<Widget>().separateWith(separateHeight, first: true, last: true),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
