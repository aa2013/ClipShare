
import 'dart:ui';

import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/loading/downloading_dialog.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import 'crypto.dart';

/// 单个弹窗按钮配置。
class DialogAction {
  final String? text;
  final VoidCallback? onPressed;

  const DialogAction({
    this.text,
    this.onPressed,
  });
}

/// 提示弹窗底部按钮组：confirm/cancel 位于右侧，neutral 位于左侧。
///
/// 槽位传了才显示，未显式传 confirm 时默认提供一个"确定"按钮。
class DialogActions {
  final DialogAction? confirm;
  final DialogAction? cancel;
  final DialogAction? neutral;

  const DialogActions({
    this.confirm = const DialogAction(),
    this.cancel,
    this.neutral,
  });

  /// 三个槽位都未配置时表示不展示任何按钮。
  bool get isEmpty => confirm == null && cancel == null && neutral == null;
}

class DialogManager {
  DialogManager._();

  static const tag = 'DialogManager';
  static final _displayingDialogs = <String>{};
  static final _dialogDisplayLock = Lock(); // 创建互斥锁

  /// 公共的弹窗进出场过渡：毛玻璃模糊 + 淡入淡出，各弹窗统一复用。
  static Widget _dialogTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5 * animation.value,
          sigmaY: 5 * animation.value,
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  /// 打开一个自定义 widget 的通用弹窗。
  DialogController open(
    BuildContext context,
    Widget widget, {
    bool dismissible = true,
    String? barrierLabel,
  }) {
    final dlgCtl = DialogController(context);
    final future = showGeneralDialog(
      barrierDismissible: dismissible,
      barrierLabel: dismissible ? barrierLabel ?? '' : null,
      context: context,
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, animation, secondaryAnimation) => Container(
        key: dlgCtl.key,
        child: widget,
      ),
    );
    dlgCtl.future = future.then((value) => dlgCtl.close());
    return dlgCtl;
  }

  /// 构建提示弹窗底部按钮。
  List<Widget> _buildTipsActions(
    DialogController dlgCtl,
    bool autoDismiss,
    DialogActions actions,
  ) {
    final confirm = actions.confirm;
    final cancel = actions.cancel;
    final neutral = actions.neutral;
    if (actions.isEmpty) {
      return const [];
    }

    TextButton buildButton(DialogAction action, String fallbackText) {
      return TextButton(
        onPressed: () {
          if (autoDismiss) {
            dlgCtl.close();
          }
          action.onPressed?.call();
        },
        child: Text(action.text ?? fallbackText),
      );
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (neutral != null)
            buildButton(neutral, TranslationKey.dialogNeutralText.tr),
          IntrinsicWidth(
            child: Row(
              children: [
                if (cancel != null)
                  buildButton(cancel, TranslationKey.dialogCancelText.tr),
                if (confirm != null)
                  buildButton(confirm, TranslationKey.dialogConfirmText.tr),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// 弹出提示/确认弹窗；相同 title+text 的内容会去重，只弹出一个。
  Future<DialogController?> tips(
    BuildContext context, {
    required String text,
    bool selectable = false,
    Widget? customWidget,
    String? title,
    bool autoDismiss = true,
    double maxWidth = 400,
    DialogActions actions = const DialogActions(),
  }) async {
    var cancelDisplay = false;
    late String md5;
    await _dialogDisplayLock.synchronized(() {
      md5 = CryptoUtil.toMD5('$title$text');
      if (_displayingDialogs.contains(md5)) {
        cancelDisplay = true;
      } else {
        _displayingDialogs.add(md5);
      }
    });
    if (cancelDisplay || !context.mounted) {
      return null;
    }
    title = title ?? TranslationKey.tips.tr;
    final dlgCtl = DialogController(context);

    final feature = showGeneralDialog(
      context: context,
      barrierDismissible: autoDismiss,
      barrierLabel: TranslationKey.tips.tr,
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopScope(
          canPop: autoDismiss,
          key: dlgCtl.key,
          child: AlertDialog(
            title: Text(title!),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: selectable ? SelectableText(text) : Text(text),
                    ),
                  ),
                  ?customWidget,
                ],
              ),
            ),
            actions: _buildTipsActions(dlgCtl, autoDismiss, actions),
          ),
        );
      },
    );
    dlgCtl.future = feature.then((value) => dlgCtl.close()).whenComplete(() => _displayingDialogs.remove(md5));
    return dlgCtl;
  }

  /// 弹出加载中弹窗。
  DialogController loading(
    BuildContext context, {
    bool dismissible = false,
    bool showCancel = false,
    void Function()? onCancel,
    String? loadingText,
    LoadingProgressController? controller,
  }) {
    final dlgCtl = DialogController(context);
    final feature = showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: TranslationKey.loading.tr,
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopScope(
          canPop: dismissible,
          key: dlgCtl.key,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlertDialog(
                content: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        child: Loading(
                          width: 32,
                          description: loadingText != null ? Text(loadingText) : null,
                          controller: controller,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: showCancel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                dlgCtl.close();
                                onCancel?.call();
                              },
                              child: Text(TranslationKey.dialogCancelText.tr),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    dlgCtl.future = feature.then((value) => dlgCtl.close());
    return dlgCtl;
  }

  /// 弹出下载弹窗。
  DialogController downloading(
    BuildContext context, {
    required String url,
    required String filePath,
    required Widget content,
    required void Function(bool) onFinished,
    void Function(dynamic error, dynamic stack)? onError,
    void Function()? onCancel,
  }) {
    final dlgCtl = DialogController(context);
    final feature = showGeneralDialog(
      context: context,
      barrierLabel: TranslationKey.downloading.tr,
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopScope(
          canPop: false,
          key: dlgCtl.key,
          child: DownloadDialog(
            url: url,
            savePath: filePath,
            content: content,
            onCancel: onCancel,
            onFinished: onFinished,
            onError: onError,
          ),
        );
      },
    );
    dlgCtl.future = feature.then((value) => dlgCtl.close());
    return dlgCtl;
  }

  /// 按 id 关闭指定弹窗；不存在时返回 false。
  Future<bool> closeById(int id, [dynamic value]) {
    return DialogController.closeById(id, value);
  }

  /// 关闭当前所有存活弹窗。
  Future<void> closeAll() {
    return DialogController.closeAll();
  }
}

class DialogController {
  static int _lastDialogId = 0;
  final int id = _lastDialogId++;
  final BuildContext context;
  late final Future future;
  final GlobalKey key = GlobalKey();
  static const tag = 'DialogController';

  /// 全局存活注册表：记录所有尚未关闭的弹窗，key 为自增 id。
  static final Map<int, DialogController> _dialogKeyMap = {};

  bool get closed => !_dialogKeyMap.containsKey(id);

  DialogController(this.context) {
    _dialogKeyMap[id] = this;
  }

  /// 关闭本弹窗。
  ///
  /// 栈顶弹窗走 pop（保留退场动画并回传 [value]）；被上层遮挡的中间弹窗
  /// Navigator 不允许 pop，只能 removeRoute 直接摘除（无退场动画）。
  /// 调用本身幂等：已被关闭或正在关闭时直接返回 true。
  Future<bool> close([dynamic value]) async {
    if (_dialogKeyMap.remove(id) == null) {
      return true;
    }
    try {
      if (key.currentContext == null) {
        // 弹窗刚 push，widget 尚未挂载时等待一帧后再取。
        logger.debug(tag, 'dialog($id) currentContext = null, wait 100ms');
        await Future.delayed(100.ms);
      }
      final dialogContext = key.currentContext;
      if (dialogContext == null || !dialogContext.mounted) {
        logger.debug(tag, 'dialog.key.currentContext is null or unmounted');
        return false;
      }
      return _removeRoute(dialogContext, value);
    } catch (err, stack) {
      // 关闭失败时恢复注册，允许后续重试。
      _dialogKeyMap[id] = this;
      logger.error(tag, '$err,$stack');
      return false;
    }
  }

  /// 真正执行弹窗 route 的移除，须在 widget 挂载后（同步调用）进行。
  bool _removeRoute(BuildContext dialogContext, dynamic value) {
    final route = ModalRoute.of(dialogContext);
    if (route == null) {
      return false;
    }
    final navigator = Navigator.of(dialogContext);
    if (route.isCurrent) {
      navigator.pop(value);
    } else {
      navigator.removeRoute(route);
    }
    return true;
  }

  /// 按 id 关闭指定弹窗。
  static Future<bool> closeById(int id, [dynamic value]) async {
    final dialog = _dialogKeyMap[id];
    if (dialog == null) {
      return false;
    }
    return dialog.close(value);
  }

  /// 关闭当前所有存活弹窗（快照遍历，避免关闭过程中修改表结构）。
  static Future<void> closeAll() async {
    final dialogs = List<DialogController>.of(_dialogKeyMap.values);
    for (final dialog in dialogs) {
      await dialog.close();
    }
  }
}

/// 全局唯一弹窗管理实例。
final dialogManager = DialogManager._();
