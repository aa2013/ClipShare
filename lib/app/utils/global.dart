import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/base/custom_title_bar_layout.dart';
import 'package:clipshare/app/widgets/dialog/downloading_dialog.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class Global {
  Global._private();

  static const tag = "GlobalUtils";
  static var _notificationReady = false;

  static final _notification = FlutterLocalNotificationsPlugin();

  static Future<void> _initNotifications() async {
    if (_notificationReady) return;
    const iosSettings = DarwinInitializationSettings();
    var iconPath = File.fromUri(WindowsImage.getAssetUri(Constants.logoPngPath)).absolute.path;
    final windowsSettings = WindowsInitializationSettings(
      appName: Constants.appName,
      appUserModelId: Constants.pkgName,
      guid: Constants.appGuid,
      iconPath: iconPath,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');

    final settings = InitializationSettings(
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notification.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        windowManager.show();
      },
    );
    _notificationReady = true;
  }

  static void toast(String text) {
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.toast(text);
  }

  static Future<void> notify({
    String title = Constants.appName,
    required String content,
    String? payload,
  }) async {
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      androidChannelService.sendNotify(content);
      return;
    }
    if (!_notificationReady) {
      await _initNotifications();
    }
    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    await _notification.show(
      0,
      title,
      content,
      notificationDetails,
      payload: payload,
    );
  }

  static void showSnackBar(
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    String text,
    Color color,
  ) {
    assert(context != null || scaffoldMessengerState != null);
    if (context != null) {
      AnimatedSnackBar(
        builder: ((context) {
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(125),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: MaterialAnimatedSnackBar(
              messageText: text,
              backgroundColor: color,
              type: AnimatedSnackBarType.info,
            ),
          );
        }),
        desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
        mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        duration: 4.s,
      ).show(context);
    } else {
      final snackbar = SnackBar(
        content: Text(text),
        backgroundColor: color,
      );
      scaffoldMessengerState!.showSnackBar(snackbar);
    }
  }

  static void showSnackBarSuc({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.blue.shade700);
  }

  static void showSnackBarErr({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.redAccent);
  }

  static void showSnackBarWarn({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.orange);
  }

  static DialogController showDialog(BuildContext context, Widget widget, {bool dismissible = true, String? barrierLabel}) {
    final dlgCtl = DialogController(context);
    final future = showGeneralDialog(
      barrierDismissible: dismissible,
      barrierLabel: dismissible ? barrierLabel ?? '' : null,
      context: context,
      transitionBuilder: (context, anim1, anim2, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * anim1.value,
              sigmaY: 5 * anim1.value,
            ),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Container(
        key: dlgCtl.key,
        child: widget,
      ),
    );
    dlgCtl.future = future.then((value) => dlgCtl.close());
    return dlgCtl;
  }

  static DialogController? showTipsDialog({
    required BuildContext context,
    required String text,
    String? title,
    String? okText,
    String? cancelText,
    String? neutralText,
    bool showCancel = false,
    bool showOk = true,
    bool showNeutral = false,
    void Function()? onOk,
    void Function()? onCancel,
    void Function()? onNeutral,
    bool autoDismiss = true,
  }) {
    try {
      final appConfig = Get.find<ConfigService>();
      if (appConfig.authenticating.value) {
        Log.warn(tag, "cancel show tips dialog because of authenticating");
        return null;
      }
    } catch (_) {}
    title = title ?? TranslationKey.tips.tr;
    okText = okText ?? TranslationKey.dialogConfirmText.tr;
    cancelText = cancelText ?? TranslationKey.dialogCancelText.tr;
    neutralText = neutralText ?? TranslationKey.dialogNeutralText.tr;
    final dlgCtl = DialogController(context);
    final feature = showGeneralDialog(
      context: context,
      barrierDismissible: autoDismiss,
      barrierLabel: TranslationKey.tips.tr,
      transitionBuilder: (context, anim1, anim2, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * anim1.value,
              sigmaY: 5 * anim1.value,
            ),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopScope(
          canPop: autoDismiss,
          key: dlgCtl.key,
          child: AlertDialog(
            title: Text(title!),
            content: SingleChildScrollView(child: Text(text)),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: showNeutral,
                    child: TextButton(
                      onPressed: () {
                        if (autoDismiss) {
                          dlgCtl.close();
                        }
                        onNeutral?.call();
                      },
                      child: Text(neutralText!),
                    ),
                  ),
                  IntrinsicWidth(
                    child: Row(
                      children: [
                        Visibility(
                          visible: showCancel,
                          child: TextButton(
                            onPressed: () {
                              if (autoDismiss) {
                                dlgCtl.close();
                              }
                              onCancel?.call();
                            },
                            child: Text(cancelText!),
                          ),
                        ),
                        Visibility(
                          visible: showOk,
                          child: TextButton(
                            onPressed: () {
                              if (autoDismiss) {
                                dlgCtl.close();
                              }
                              onOk?.call();
                            },
                            child: Text(okText!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    dlgCtl.future = feature.then((value) => dlgCtl.close());
    return dlgCtl;
  }

  static DialogController showLoadingDialog({
    required BuildContext context,
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
      transitionBuilder: (context, anim1, anim2, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * anim1.value,
              sigmaY: 5 * anim1.value,
            ),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
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

  static DialogController showDownloadingDialog({
    required BuildContext context,
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
      transitionBuilder: (context, anim1, anim2, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * anim1.value,
              sigmaY: 5 * anim1.value,
            ),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
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
}

class DialogController {
  static int _lastDialogId = 0;
  final int id = _lastDialogId++;
  final BuildContext context;
  late final Future future;
  final GlobalKey key = GlobalKey();
  static const tag = 'DialogController';

  bool get closed => !_dialogKeyMap.containsKey(id);
  static final Map<int, DialogController> _dialogKeyMap = {};

  DialogController(this.context) {
    _dialogKeyMap[id] = this;
  }

  Future<bool> close([dynamic value]) async {
    var dialog = _dialogKeyMap[id];
    if (dialog == null) {
      return true;
    }
    try {
      if (dialog.key.currentContext == null) {
        Log.debug(tag, "dialog($id) currentContext = null, wait 100ms");
        await Future.delayed(100.ms);
      }
      final routeDialog = ModalRoute.of(dialog.key.currentContext!);
      if (routeDialog != null) {
        _dialogKeyMap.remove(id);
        Navigator.removeRoute(dialog.context, routeDialog);
      }
      return true;
    } catch (err, stack) {
      Log.error(tag, "$err,$stack");
      return false;
    }
  }
}
