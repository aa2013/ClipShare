import 'dart:async';

import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

/// 配对验证码对话框
class PairingPinDialog extends StatefulWidget {
  /// 关闭弹窗回调
  final VoidCallback onClose;

  /// 提交验证码回调，参数为明文验证码，由调用方加密发送。
  final ValueChanged<String> onSendCode;

  /// 用户取消配对回调。
  final VoidCallback onCancel;

  /// 对端的配对结果流（发起时按设备 id 过滤），
  /// 用于区分成功关闭弹窗与失败清空重输。
  final Stream<DevicePaired> pairingResults;

  /// 对端取消配对的信号流（发起时按设备 id 过滤，可为空），
  /// 收到后静默关闭本机弹窗。
  final Stream<DevicePairingCanceled>? cancelSignal;

  /// 配对提交后的超时时长。
  final Duration timeout;

  const PairingPinDialog({
    super.key,
    required this.onClose,
    required this.onSendCode,
    required this.onCancel,
    required this.pairingResults,
    this.cancelSignal,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  State<PairingPinDialog> createState() => _PairingPinDialogState();
}

class _PairingPinDialogState extends State<PairingPinDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  /// 是否处于等待配对结果阶段，期间禁止重复提交与取消。
  var _submitting = false;

  /// 提交后超时未收到配对结果。
  var _showTimeout = false;

  /// 超时计时器，提交后等待配对结果用。
  Timer? _timeoutTimer;

  /// 对端回传的配对结果订阅。
  StreamSubscription<DevicePaired>? _resultsSubscription;

  /// 对端取消配对信号订阅。
  StreamSubscription<DevicePairingCanceled>? _cancelSubscription;

  @override
  void initState() {
    super.initState();
    _resultsSubscription = widget.pairingResults.listen(_onPairingResult);
    _cancelSubscription = widget.cancelSignal?.listen(_onPairingCanceled);
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    _cancelSubscription?.cancel();
    _timeoutTimer?.cancel();
    _focusNode.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// 处理对端配对结果。
  ///
  /// 结果为 [value].result：成功时取消等待并关闭弹窗；失败时取消等待计时并清空
  /// 已输入的验证码，焦点归还输入框以便重新输入（配对错误提示通过 snackbar 反馈）。
  void _onPairingResult(DevicePaired value) {
    if (!mounted) {
      return;
    }
    if (value.result) {
      _timeoutTimer?.cancel();
      widget.onClose();
      return;
    }
    _timeoutTimer?.cancel();
    setState(() {
      _submitting = false;
      _showTimeout = false;
    });
    _pinController.clear();
    _focusNode.requestFocus();
    snackbar.error(context, TranslationKey.devicePagePairingErrorText.tr);
  }

  /// 配对取消
  void _onPairingCanceled(DevicePairingCanceled event){
    if (!mounted) {
      return;
    }
    _timeoutTimer?.cancel();
    widget.onClose();
  }

  /// 提交验证码：满六位才允许提交，提交后进入等待状态并启动超时计时。
  void _submit() {
    if (_pinController.text.length != 6 || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _showTimeout = false;
    });
    widget.onSendCode(_pinController.text);
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _submitting = false;
          _showTimeout = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationKey.devicePagePairingDialogTitle.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pinput(
            length: 6,
            controller: _pinController,
            focusNode: _focusNode,
            autofocus: true,
            // 满位后保持焦点（默认满位即失焦会导致回车无法触发 onSubmitted）。
            closeKeyboardWhenCompleted: false,
            defaultPinTheme: context.pinInputTheme,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (_showTimeout)
            Text(
              TranslationKey.devicePagePairingTimeoutText.tr,
              style: const TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  widget.onCancel();
                  widget.onClose();
                },
          child: Text(TranslationKey.dialogCancelText.tr),
        ),
        TextButton(
          onPressed: _pinController.text.length == 6 && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(TranslationKey.devicePagePairingDialogConfirmText.tr),
        ),
      ],
    );
  }
}
