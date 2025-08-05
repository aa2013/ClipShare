import 'dart:io';

import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/white_black_rule.dart';
import 'package:clipshare/app/modules/views/white_black_list_page.dart';
import 'package:clipshare/app/services/android_notification_listener_service.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/modules/clean_data_module/clean_data_controller.dart';
import 'package:clipshare/app/modules/clean_data_module/clean_data_page.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SettingsController extends GetxController with WidgetsBindingObserver implements ForwardStatusListener {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();

  //region 属性
  final tag = "ProfilePage";

  //通知权限
  var notifyHandler = NotifyPermHandler();

  //悬浮窗权限
  var floatHandler = FloatPermHandler();

  //检查电池优化
  var ignoreBatteryHandler = IgnoreBatteryHandler();
  final hasNotifyPerm = false.obs;
  final hasShizukuPerm = false.obs;
  final hasFloatPerm = false.obs;
  final hasIgnoreBattery = false.obs;
  final hasSmsReadPerm = true.obs;
  final hasAccessibilityPerm = false.obs;
  final hasNotificationRecordPerm = false.obs;
  final forwardServerConnected = false.obs;
  final updater = 0.obs;

  //region environment status widgets
  final Rx<Widget> envStatusIcon = Rx<Widget>(const Loading(width: 32));
  final Rx<Widget> envStatusTipContent = Rx<Widget>(
    Text(
      TranslationKey.envStatusLoadingText.tr,
      style: const TextStyle(fontSize: 16),
    ),
  );
  final Rx<Widget> envStatusTipDesc = Rx<Widget>(const SizedBox.shrink());
  final Rx<Color?> envStatusBgColor = Rx<Color?>(null);
  final Rx<Widget?> envStatusAction = Rx<Widget?>(null);
  final warningIcon = const Icon(
    Icons.warning,
    size: 40,
  );

  Color get warningBgColor => Theme.of(Get.context!).colorScheme.surface;
  final normalIcon = const Icon(
    Icons.check_circle_outline_outlined,
    size: 40,
    color: Colors.blue,
  );

  //region Shizuku
  Widget get shizukuEnvNormalTipContent => Text(
    TranslationKey.shizukuModeStatusTitle.tr,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey,
    ),
  );

  Widget get shizukuEnvErrorTipContent => Text(
    TranslationKey.shizukuModeStatusTitle.tr,
    style: const TextStyle(fontSize: 16),
  );
  final Rx<int?> shizukuVersion = Rx<int?>(null);

  Widget get shizukuEnvNormalTipDesc => Obx(
    () => Text(
      TranslationKey.shizukuModeRunningDescription.trParams({
        'version': shizukuVersion.value?.toString() ?? "",
      }),
      style: const TextStyle(fontSize: 14, color: Color(0xff6d6d70)),
    ),
  );

  Widget get shizukuEnvErrorTipDesc => Text(
    TranslationKey.serverNotRunningDescription.tr,
    style: const TextStyle(fontSize: 14),
  );

  //endregion

  //region Root
  Widget get rootEnvNormalTipContent => Text(
    TranslationKey.rootModeStatusTitle.tr,
    style: const TextStyle(fontSize: 16),
  );

  Widget get rootEnvErrorTipContent => Text(
    TranslationKey.rootModeStatusTitle.tr,
    style: const TextStyle(fontSize: 16),
  );

  Widget get rootEnvNormalTipDesc => Text(
    TranslationKey.rootModeRunningDescription.tr,
    style: const TextStyle(fontSize: 14),
  );

  Widget get rootEnvErrorTipDesc => Text(
    TranslationKey.serverNotRunningDescription.tr,
    style: const TextStyle(fontSize: 14),
  );

  //endregion

  //region Android Pre 10
  Widget get androidPre10TipContent => Text(
    TranslationKey.noSpecialPermissionRequired.tr,
    style: const TextStyle(fontSize: 16),
  );

  Widget get androidPre10EnvNormalTipDesc => Text(
    "Android ${appConfig.osVersion}",
    style: const TextStyle(fontSize: 14),
  );

  //endregion

  //region ignore
  final ignoreTipContent = Text(
    TranslationKey.envPermissionIgnored.tr,
    style: const TextStyle(fontSize: 16),
  );

  final ignoreTipDesc = Text(
    TranslationKey.envPermissionIgnoredDescription.tr,
    style: const TextStyle(fontSize: 14),
  );

  //endregion

  //endregion

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    sktService.addForwardStatusListener(this);
    envStatusAction.value = IconButton(
      icon: const Icon(Icons.more_horiz_outlined),
      tooltip: TranslationKey.switchWorkingMode.tr,
      onPressed: onEnvironmentStatusCardActionClick,
    );
    checkPermissions();
    checkAndroidEnvPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkPermissions();
      if (envStatusIcon.value == warningIcon) {
        checkAndroidEnvPermission();
      }
    }
  }

  //endregion

  //region 页面方法
  void gotoCleanDataPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.CLEAN_DATA);
    } else {
      final homeController = Get.find<HomeController>();
      Get.lazyPut(() => CleanDataController());
      homeController.openEndDrawer(
        drawer: CleanDataPage(),
        onDrawerClosed: () {
          Get.delete<CleanDataController>();
        },
      );
    }
  }

  void gotoFilterRuleListPage() {
    final isSmallScreen = appConfig.isSmallScreen;
    final homeController = Get.find<HomeController>();
    final currentMode = appConfig.currentNotificationWhiteBlackMode.obs;
    final page = Obx(
      () => WhiteBlackListPage(
        title: TranslationKey.notificationRules.tr,
        showMode: WhiteBlackMode.all,
        currentMode: currentMode.value,
        blacklist: List.from(appConfig.notificationBlackList),
        whitelist: List.from(appConfig.notificationWhiteList),
        onModeChanged: (mode, enabled) {
          currentMode.value = mode;
        },
        onDone: (WhiteBlackMode mode, Map<WhiteBlackMode, List<FilterRule>> data) {
          final blacklist = data[WhiteBlackMode.black]!;
          final whitelist = data[WhiteBlackMode.white]!;
          appConfig.setNotificationBlackWhiteList(mode, blacklist, whitelist);
          if (!isSmallScreen) {
            homeController.closeEndDrawer();
          }
        },
      ),
    );
    if (isSmallScreen) {
      Get.to(page);
    } else {
      homeController.openEndDrawer(drawer: page);
    }
  }

  void gotoBlackListPage() {
    final isSmallScreen = appConfig.isSmallScreen;
    final homeController = Get.find<HomeController>();
    final page = Obx(
      () => WhiteBlackListPage(
        title: TranslationKey.blacklistRules.tr,
        showMode: WhiteBlackMode.black,
        enabled: appConfig.enableContentBlackList,
        blacklist: List.from(appConfig.contentBlackList),
        onModeChanged: (mode, enabled) {
          if (mode == WhiteBlackMode.black) {
            appConfig.setEnableContentBlackList(enabled);
          }
        },
        onDone: (_, Map<WhiteBlackMode, List<FilterRule>> data) {
          appConfig.setContentBlacklist(data[WhiteBlackMode.black]!);
          if (!isSmallScreen) {
            homeController.closeEndDrawer();
          }
        },
      ),
    );
    if (isSmallScreen) {
      Get.to(page);
    } else {
      homeController.openEndDrawer(drawer: page);
    }
  }

  ///EnvironmentStatusCard click
  Future<void> onEnvironmentStatusCardClick() async {
    if (envStatusBgColor.value != warningBgColor) return;
    await clipboardManager.requestPermission(appConfig.workingMode!);
    clipboardManager.stopListening();
    clipboardManager.startListening(
      env: appConfig.workingMode,
      way: appConfig.clipboardListeningWay,
      notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
    );
  }

  ///EnvironmentStatusCard action click
  void onEnvironmentStatusCardActionClick() {
    Get.toNamed(Routes.WORKING_MODE_SELECTION);
  }

  ///检查必要权限
  Future<void> checkPermissions() async {
    if (!Platform.isAndroid) {
      return;
    }
    notifyHandler.hasPermission().then((v) {
      hasNotifyPerm.value = v;
    });
    floatHandler.hasPermission().then((v) {
      hasFloatPerm.value = v;
    });
    ignoreBatteryHandler.hasPermission().then((v) {
      hasIgnoreBattery.value = v;
    });
    PermissionHelper.testAndroidReadSms().then((granted) {
      //有权限或者不需要读取短信则视为有权限
      hasSmsReadPerm.value = granted || !appConfig.enableSmsSync;
    });
    PermissionHelper.testAndroidAccessibilityPerm().then((granted) {
      hasAccessibilityPerm.value = granted;
      if (!granted && appConfig.sourceRecord) {
        Global.showTipsDialog(
          context: Get.context!,
          text: TranslationKey.noAccessibilityPermTips.tr,
          showCancel: true,
          okText: TranslationKey.goAuthorize.tr,
          onOk: () {
            PermissionHelper.reqAndroidAccessibilityPerm();
          },
        );
      }
    });
    NotificationListenerService.isPermissionGranted().then((granted) {
      hasNotificationRecordPerm.value = granted;
      final androidNotificationListenerService = Get.find<AndroidNotificationListenerService>();
      if (granted && appConfig.enableRecordNotification && !androidNotificationListenerService.listening) {
        androidNotificationListenerService.startListening();
      } else if (!granted && appConfig.enableRecordNotification) {
        Global.showTipsDialog(
          context: Get.context!,
          text: TranslationKey.noNotificationRecordPermTips.tr,
          showCancel: true,
          okText: TranslationKey.goAuthorize.tr,
          onOk: () {
            NotificationListenerService.requestPermission();
          },
        );
      }
    });
  }

  ///检查 Android 工作环境必要权限
  Future<void> checkAndroidEnvPermission([bool restart = false]) async {
    if (!Platform.isAndroid) {
      return;
    }
    final mode = appConfig.workingMode;
    bool hasPermission = true;
    bool listening = await clipboardManager.checkIsRunning();
    if (!listening) {
      await Future.delayed(const Duration(seconds: 2), () async {
        listening = await clipboardManager.checkIsRunning();
      });
    }
    switch (mode) {
      case EnvironmentType.shizuku:
        hasPermission = await clipboardManager.checkPermission(mode!);
        envStatusTipContent.value = hasPermission ? shizukuEnvNormalTipContent : shizukuEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening ? shizukuEnvNormalTipDesc : shizukuEnvErrorTipDesc;
        if (hasPermission && shizukuVersion.value == null) {
          shizukuVersion.value = await clipboardManager.getShizukuVersion();
        }
        break;
      case EnvironmentType.root:
        hasPermission = await clipboardManager.checkPermission(mode!);
        envStatusTipContent.value = hasPermission && listening ? rootEnvNormalTipContent : rootEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening ? rootEnvNormalTipDesc : rootEnvErrorTipDesc;
        break;
      case EnvironmentType.androidPre10:
        hasPermission = true;
        envStatusTipContent.value = androidPre10TipContent;
        envStatusTipDesc.value = androidPre10EnvNormalTipDesc;
        break;
      default:
        hasPermission = true;
        envStatusTipContent.value = ignoreTipContent;
        envStatusTipDesc.value = ignoreTipDesc;
    }
    envStatusIcon.value = hasPermission && listening ? normalIcon : warningIcon;
    envStatusBgColor.value = hasPermission && listening ? null : warningBgColor;
    if (restart) {
      await clipboardManager.stopListening();
      clipboardManager.startListening(
        env: mode,
        way: appConfig.clipboardListeningWay,
        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
      );
      checkAndroidEnvPermission();
    }
  }

  ///跳转密码设置页面
  void gotoSetPwd() {
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => AuthPasswordInput(
          onFinished: (a, b) => a == b,
          onOk: (input) {
            appConfig.setAppPassword(input);
            return true;
          },
          again: true,
          showCancelBtn: true,
        ),
      ),
    );
  }

  @override
  void onForwardServerConnected() {
    forwardServerConnected.value = true;
  }

  @override
  void onForwardServerDisconnected() {
    forwardServerConnected.value = false;
  }

  //endregion
}
