import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/enums/backup_source.dart';
import 'package:clipshare/app/data/enums/backup_type.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/exceptions/user_cancel_backup.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/licenses_module/licenses_controller.dart';
import 'package:clipshare/app/modules/licenses_module/licenses_page.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/log_module/log_page.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/statistics_module/statistics_controller.dart';
import 'package:clipshare/app/modules/statistics_module/statistics_page.dart';
import 'package:clipshare/app/modules/update_log_module/update_log_controller.dart';
import 'package:clipshare/app/modules/update_log_module/update_log_page.dart';
import 'package:clipshare/app/services/android_notification_listener_service.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/storage_config_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/dialog/multi_select_dialog.dart';
import 'package:clipshare/app/widgets/dialog/s3_config_edit_dialog.dart';
import 'package:clipshare/app/widgets/dialog/single_select_dialog.dart';
import 'package:clipshare/app/widgets/dialog/webdav_config_edit_dialog.dart';
import 'package:clipshare/app/widgets/file_browser.dart';
import 'package:clipshare/app/widgets/radio_group.dart';
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
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
/// GetX Template Generator - fb.com/htngu.99

class SettingsController extends GetxController with WidgetsBindingObserver implements ForwardStatusListener, ScreenOpenedObserver {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final sktService = Get.find<SocketService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final tagService = Get.find<TagService>();
  final devService = Get.find<DeviceService>();
  final ruleController = Get.find<RulesController>();

  //region 属性
  final tag = "SettingsController";

  final hasWorkingModePerm = false.obs;

  //通知权限
  var notifyHandler = NotifyPermHandler();

  //悬浮窗权限
  var floatHandler = FloatPermHandler();

  //剪贴板权限
  var clipboardHandler = ClipboardPermHandler();

  //检查电池优化
  var ignoreBatteryHandler = IgnoreBatteryHandler();

  //检查IOS相册权限
  var iosPhotosHandler = IosPhotosHandler();

  final hasNotifyPerm = false.obs;
  final hasIOSPhotosPerm = false.obs;
  final hasShizukuPerm = false.obs;
  final hasFloatPerm = false.obs;
  final hasIgnoreBattery = false.obs;
  final hasSmsReadPerm = true.obs;
  final hasAccessibilityPerm = false.obs;
  final hasNotificationRecordPerm = false.obs;
  final hasClipboardPerm = true.obs;
  final forwardServerStatus = ForwardServerStatus.disconnected.obs;
  final updater = 0.obs;
  Timer? _screenEventTimer;
  int _envStatusCheckSeq = 0;
  bool _checkingAccessibilityPerm = false;
  bool _accessibilityPermDialogPending = false;
  static const _accessibilityPermissionRecheckDelay = Duration(seconds: 1);

  //region environment status widgets
  final Rx<Widget> envStatusIcon = Rx<Widget>(envLoadingIcon);
  final Rx<Widget> envStatusTipContent = Rx<Widget>(
    Text(
      TranslationKey.envStatusLoadingText.tr,
      style: const TextStyle(fontSize: 16),
    ),
  );
  final Rx<Widget> envStatusTipDesc = Rx<Widget>(const SizedBox.shrink());
  final Rx<Color?> envStatusBgColor = Rx<Color?>(null);
  final Rx<Widget?> envStatusAction = Rx<Widget?>(null);
  static const envLoadingIcon = Loading(width: 32);
  static const warningIcon = Icon(
    Icons.warning,
    size: 40,
  );

  Color get warningBgColor {
    final theme = Theme.of(Get.context!);
    final baseColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final overlay = theme.colorScheme.error.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08);
    return Color.alphaBlend(overlay, baseColor);
  }

  Color get ignoredBgColor {
    final theme = Theme.of(Get.context!);
    final baseColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    return Color.alphaBlend(Colors.blueGrey.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08), baseColor);
  }
  static const normalIcon = Icon(
    Icons.check_circle_outline_outlined,
    size: 40,
    color: Colors.blue,
  );
  static const ignoredIcon = Icon(
    Icons.block_outlined,
    size: 40,
    color: Colors.blueGrey,
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
      TranslationKey.shizukuModeRunningDesc.trParams({
        'version': shizukuVersion.value?.toString() ?? "",
      }),
      style: const TextStyle(fontSize: 14, color: Color(0xff6d6d70)),
    ),
  );

  Widget get shizukuEnvErrorTipDesc => Text(
    TranslationKey.serverNotRunningDesc.tr,
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
    TranslationKey.rootModeRunningDesc.tr,
    style: const TextStyle(fontSize: 14),
  );

  Widget get rootEnvErrorTipDesc => Text(
    TranslationKey.serverNotRunningDesc.tr,
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
    TranslationKey.envPermissionIgnoredDesc.tr,
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
    if (Platform.isAndroid) {
      ScreenOpenedListener.inst.register(this);
    }
    connRegService.addForwardStatusListener(this);
    envStatusAction.value = IconButton(
      icon: const Icon(Icons.more_horiz_outlined),
      tooltip: TranslationKey.switchWorkingMode.tr,
      onPressed: onEnvironmentStatusCardActionClick,
    );
    checkPermissions();
    checkAndroidEnvPermission();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    connRegService.removeForwardStatusListener(this);
    _screenEventTimer?.cancel();
    if (Platform.isAndroid) {
      ScreenOpenedListener.inst.remove(this);
    }
    super.onClose();
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
      homeController.pushDrawer(
        widget: CleanDataPage(),
        beforeClosed: () {
          Get.delete<CleanDataController>();
          return true;
        },
      );
    }
  }

  void gotoStatisticPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.STATISTICS);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(StatisticsController());
      homeController.pushDrawer(
        widget: StatisticsPage(),
        width: 430,
        beforeClosed: () {
          Get.delete<StatisticsController>();
          homeController.resetDrawerWidth();
          return true;
        },
      );
    }
  }

  void gotoLogPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.LOG);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(LogController());
      homeController.pushDrawer(
        widget: LogPage(),
        beforeClosed: () {
          Get.delete<LogController>();
          return true;
        },
      );
    }
  }

  void gotoLicensesPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.LICENSES);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(LicensesController());
      homeController.pushDrawer(
        widget: LicensesPage(),
        beforeClosed: () {
          Get.delete<LicensesController>();
          return true;
        },
      );
    }
  }

  void gotoUpdateLogsPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.UPDATE_LOG);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(UpdateLogController());
      homeController.pushDrawer(
        widget: UpdateLogPage(),
        beforeClosed: () {
          Get.delete<UpdateLogController>();
          return true;
        },
      );
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
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    if(Platform.isAndroid){
      floatHandler.hasPermission().then((v) {
        hasFloatPerm.value = v;
      });
      ignoreBatteryHandler.hasPermission().then((v) {
        hasIgnoreBattery.value = v;
      });
      clipboardHandler.hasPermission().then((v) {
        hasClipboardPerm.value = v;
      });
      PermissionHelper.testAndroidReadSms().then((granted) {
        //有权限或者不需要读取短信则视为有权限
        hasSmsReadPerm.value = granted || !ruleController.enableSmsSync;
      });
      _checkAccessibilityPermission();
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
    if(Platform.isIOS){
      iosPhotosHandler.hasPermission().then((v){
        hasIOSPhotosPerm.value = v;
      });
    }
    notifyHandler.hasPermission().then((v) {
      hasNotifyPerm.value = v;
    });
  }

  ///检查无障碍权限，来源记录启用时先静默自动授权，失败后再提示用户手动处理
  Future<void> _checkAccessibilityPermission() async {
    if (_checkingAccessibilityPerm) {
      return;
    }
    _checkingAccessibilityPerm = true;
    try {
      var granted = await PermissionHelper.testAndroidAccessibilityPerm();
      if (!granted && !appConfig.ignoreAccessibility && appConfig.sourceRecord) {
        //启动或恢复页面时先尝试自动授权，避免支持 Shizuku/root 的设备仍然弹出手动授权提示
        granted = await PermissionHelper.tryAutoGrantAndroidAccessibilityPerm();
      }
      if (!granted && !appConfig.ignoreAccessibility && appConfig.sourceRecord) {
        //系统写入无障碍设置后服务状态可能延迟刷新，短暂等待后复查可减少误弹窗
        await Future.delayed(_accessibilityPermissionRecheckDelay);
        granted = await PermissionHelper.testAndroidAccessibilityPerm();
      }
      hasAccessibilityPerm.value = granted;
      if (granted || appConfig.ignoreAccessibility || !appConfig.sourceRecord || _accessibilityPermDialogPending) {
        return;
      }
      _accessibilityPermDialogPending = true;
      final dialog = await Global.showTipsDialog(
        context: Get.context!,
        text: TranslationKey.noAccessibilityPermTips.tr,
        showCancel: true,
        okText: TranslationKey.goAuthorize.tr,
        onOk: () async {
          await requestAccessibilityPermissionAndRefresh();
        },
        onCancel: () {
          _accessibilityPermDialogPending = false;
        },
        showNeutral: true,
        neutralText: TranslationKey.notNow.tr,
        onNeutral: () {
          _accessibilityPermDialogPending = false;
          appConfig.ignoreAccessibility = true;
        },
      );
      if (dialog == null) {
        _accessibilityPermDialogPending = false;
      } else {
        dialog.future.whenComplete(() => _accessibilityPermDialogPending = false);
      }
    } finally {
      _checkingAccessibilityPerm = false;
    }
  }

  ///请求无障碍授权后刷新设置页权限状态，避免自动授权成功后界面仍显示未授权
  Future<bool> requestAccessibilityPermissionAndRefresh() async {
    final requested = await PermissionHelper.reqAndroidAccessibilityPerm();
    //自动写入 secure settings 后系统服务列表可能稍后才同步，等待后再复查一次
    await Future.delayed(_accessibilityPermissionRecheckDelay);
    final granted = requested || await PermissionHelper.testAndroidAccessibilityPerm();
    hasAccessibilityPerm.value = granted;
    return granted;
  }

  ///检查 Android 工作环境必要权限
  Future<void> checkAndroidEnvPermission([bool restart = false]) async {
    if (!Platform.isAndroid) {
      return;
    }
    final checkSeq = ++_envStatusCheckSeq;
    _showAndroidEnvStatusLoading();
    final mode = appConfig.workingMode;
    if (restart) {
      await clipboardManager.stopListening();
      await clipboardManager.startListening(
        env: mode,
        way: appConfig.clipboardListeningWay,
        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
      );
    }
    bool hasPermission = true;
    bool listening = await clipboardManager.checkIsRunning();
    var ignoreWorkingMode = false;
    if (!listening) {
      await Future.delayed(2.s, () async {
        listening = await clipboardManager.checkIsRunning();
      });
    }
    if (checkSeq != _envStatusCheckSeq) {
      return;
    }
    switch (mode) {
      case EnvironmentType.shizuku:
        hasPermission = await clipboardManager.checkPermission(mode!);
        if (checkSeq != _envStatusCheckSeq) {
          return;
        }
        envStatusTipContent.value = hasPermission ? shizukuEnvNormalTipContent : shizukuEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening ? shizukuEnvNormalTipDesc : shizukuEnvErrorTipDesc;
        if (hasPermission && shizukuVersion.value == null) {
          shizukuVersion.value = await clipboardManager.getShizukuVersion();
          if (checkSeq != _envStatusCheckSeq) {
            return;
          }
        }
        break;
      case EnvironmentType.root:
        hasPermission = await clipboardManager.checkPermission(mode!);
        if (checkSeq != _envStatusCheckSeq) {
          return;
        }
        envStatusTipContent.value = hasPermission && listening ? rootEnvNormalTipContent : rootEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening ? rootEnvNormalTipDesc : rootEnvErrorTipDesc;
        break;
      case EnvironmentType.androidPre10:
        hasPermission = true;
        envStatusTipContent.value = androidPre10TipContent;
        envStatusTipDesc.value = androidPre10EnvNormalTipDesc;
        break;
      default:
        ignoreWorkingMode = true;
        hasPermission = true;
        envStatusTipContent.value = ignoreTipContent;
        envStatusTipDesc.value = ignoreTipDesc;
    }
    envStatusIcon.value = ignoreWorkingMode ? ignoredIcon : (hasPermission && listening ? normalIcon : warningIcon);
    envStatusBgColor.value = ignoreWorkingMode ? ignoredBgColor : (hasPermission && listening ? null : warningBgColor);
    hasWorkingModePerm.value = hasPermission;
    //有Shizuku/root权限后检查剪贴板权限状态
    if(hasPermission){
      clipboardHandler.hasPermission().then((v) {
        hasClipboardPerm.value = v;
      });
    }
  }

  /// 标记 Shizuku 当前不可用。
  ///
  /// 该方法只更新界面状态，不调用 Shizuku 权限、版本或监听检查 API，用于 binder
  /// 断开、授权被撤销等远端服务可能已经失效的回调路径。
  void markShizukuUnavailable() {
    if (!Platform.isAndroid || appConfig.workingMode != EnvironmentType.shizuku) {
      return;
    }
    _envStatusCheckSeq++;
    shizukuVersion.value = null;
    envStatusIcon.value = warningIcon;
    envStatusBgColor.value = warningBgColor;
    envStatusTipContent.value = shizukuEnvErrorTipContent;
    envStatusTipDesc.value = shizukuEnvErrorTipDesc;
    hasWorkingModePerm.value = false;
    hasShizukuPerm.value = false;
    // Shizuku 失效后，依赖提权环境的剪贴板监听也按不可用展示，避免界面保留旧状态。
    hasClipboardPerm.value = false;
  }

  /// Shows a transient checking state before Android environment status is refreshed.
  void _showAndroidEnvStatusLoading() {
    envStatusIcon.value = envLoadingIcon;
    envStatusTipContent.value = Text(
      TranslationKey.envStatusLoadingText.tr,
      style: const TextStyle(fontSize: 16),
    );
    envStatusTipDesc.value = const SizedBox.shrink();
    envStatusBgColor.value = null;
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
  void onForwardServerStatusChanged(ForwardServerStatus status) {
    forwardServerStatus.value = status;
  }

  //region 备份与恢复

  ///选择备份恢复项
  Future<List<BackupType>> _showBackupTypesDialog(BuildContext context) {
    Completer<List<BackupType>> completer = Completer();
    final types = BackupType.values.where((item) => item != BackupType.version).toList();
    late DialogController dlgController;
    dlgController = MultiSelectDialog.show<BackupType>(
      context: context,
      onSelected: (list) {
        completer.complete(list);
      },
      defaultValues: types,
      selections: types.map((item) {
        return CheckboxData(value: item, text: item.tr);
      }).toList(),
      title: Text(TranslationKey.selectBackupItems.tr),
      onCancel: () {
        completer.complete([]);
        dlgController.close();
      },
    );
    return completer.future;
  }

  ///选择备份恢复来源，本地，s3，webdav
  Future<BackupSource?> _showBackupSourceDialog(BuildContext context) {
    Completer<BackupSource?> completer = Completer();
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurface.withOpacity(0.8),
    );
    Future<bool> configWebdav() async {
      Completer<bool> inputCompleter = Completer();
      final dialog = Global.showDialog(
        context,
        WebDAVConfigEditDialog(
          initValue: appConfig.webDAVConfig,
          onOk: (config) {
            appConfig.setWebDavConfig(config);
            inputCompleter.complete(true);
          },
        ),
      );
      await dialog.future;
      if (!inputCompleter.isCompleted) {
        inputCompleter.complete(false);
      }
      return inputCompleter.future;
    }

    Future<bool> configS3() async {
      Completer<bool> inputCompleter = Completer();
      final dialog = Global.showDialog(
        context,
        S3ConfigEditDialog(
          initValue: appConfig.s3Config,
          onOk: (config) {
            appConfig.setS3Config(config);
            inputCompleter.complete(true);
          },
        ),
      );
      await dialog.future;
      if (!inputCompleter.isCompleted) {
        inputCompleter.complete(false);
      }
      return inputCompleter.future;
    }

    late DialogController dlgController;
    dlgController = SingleSelectDialog.show<BackupSource>(
      context: context,
      onSelected: (BackupSource source) async {
        if (source == BackupSource.s3 && appConfig.s3Config == null) {
          //配置s3
          if (!await configS3()) {
            completer.complete(null);
            dlgController.close();
            return;
          }
        }
        if (source == BackupSource.webdav && appConfig.webDAVConfig == null) {
          //配置 webDAV
          if (!await configWebdav()) {
            completer.complete(null);
            dlgController.close();
            return;
          }
        }
        completer.complete(source);
      },
      defaultValue: BackupSource.unknown,
      selections: BackupSource.values.where((item) => item != BackupSource.unknown).map((item) {
        Widget? desc;
        var showEditIcon = false;
        if (item == BackupSource.s3) {
          desc = Obx(
            () => Text(
              appConfig.s3Config?.displayName ?? TranslationKey.notConfigured.tr,
              style: textStyle,
            ),
          );
          showEditIcon = appConfig.s3Config?.displayName != null;
        } else if (item == BackupSource.webdav) {
          desc = Obx(
            () => Text(
              appConfig.webDAVConfig?.displayName ?? TranslationKey.notConfigured.tr,
              style: textStyle,
            ),
          );
          showEditIcon = appConfig.webDAVConfig?.displayName != null;
        }
        return RadioData(
          value: item,
          label: item.tr,
          widget: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.tr),
                    if (desc != null) desc,
                  ],
                ),
              ),
              Visibility(
                visible: showEditIcon,
                child: Tooltip(
                  message: TranslationKey.modify.tr,
                  child: IconButton(
                    onPressed: () {
                      if (item == BackupSource.s3) {
                        configS3();
                      } else {
                        configWebdav();
                      }
                    },
                    icon: const Icon(
                      Icons.edit_note,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      title: Text(TranslationKey.selectBackupSource.tr),
      onCancel: () {
        completer.complete(null);
        dlgController.close();
      },
    );
    return completer.future.whenComplete(() => dlgController.close());
  }

  ///备份
  Future<void> startBackup(BuildContext context) async {
    final backupTypes = await _showBackupTypesDialog(context);
    if (backupTypes.isEmpty) {
      Global.showSnackBarWarn(text: TranslationKey.userCancelled.tr, context: context);
      return;
    }
    final backupSource = await _showBackupSourceDialog(context);
    if (backupSource == null) {
      Global.showSnackBarWarn(text: TranslationKey.userCancelled.tr, context: context);
      return;
    }
    //若为存储服务，文件写入临时位置，备份完毕后上传至存储服务
    String? path;
    StorageClient? storageClient;
    if (backupSource == BackupSource.local) {
      path = await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
    } else {
      path = appConfig.documentsPath;
      if (backupSource == BackupSource.webdav) {
        storageClient = appConfig.webDAVConfig?.toClient();
      } else {
        storageClient = appConfig.s3Config?.toClient();
      }
      if (storageClient == null) {
        var text = TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr;
        if (backupSource != BackupSource.webdav) {
          text = TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr;
        }
        Global.showTipsDialog(text: text, context: context);
        return;
      }
    }
    if (path == null) return;
    final dialog = Global.showLoadingDialog(
      context: context,
      dismissible: false,
      showCancel: true,
      loadingText: TranslationKey.exporting.tr,
      onCancel: () {
        backupHandler.cancel();
        Global.showSnackBarSuc(text: TranslationKey.userCancelled.tr, context: context);
      },
    );
    await Future.delayed(200.ms);
    final clipboardService = Get.find<ClipboardService>();
    try {
      //如果启用了截图复制，临时关闭
      clipboardService.stopListenScreenshot();
      final result = await backupHandler.backup(Directory(path), backupTypes);
      dialog.close();
      if (!result.success) {
        if (result.exception?.err is UserCancelBackup) {
          Global.showSnackBarWarn(context: context, text: TranslationKey.cancelled.tr);
        } else {
          Global.showTipsDialog(text: TranslationKey.exportFailedAndViewLogs.tr, context: context);
        }
      } else {
        //文件备份完毕，若为存储服务，上传，显示上传进度弹窗
        var text = TranslationKey.exportSuccess.tr;
        if (storageClient != null) {
          final loadingController = LoadingProgressController(total: 100);
          final dialog = Global.showLoadingDialog(
            context: context,
            dismissible: false,
            loadingText: TranslationKey.uploading.tr,
            controller: loadingController,
          );
          final backupFileName = File(result.localPath!).fileName;
          final uploadSuccess = await storageClient.uploadFile(
            "backup/$backupFileName",
            result.localPath!,
            onProgress: (count, total) {
              int percentage = (count * 100 / total).toInt();
              loadingController.update(percentage);
            },
          );
          await dialog.close();
          if(uploadSuccess){
            File(result.localPath!).delete();
          }
          else {
            text = TranslationKey.exportFailedAndViewLogs.tr;
          }
        }
        Global.showTipsDialog(text: text, context: context);
      }
    } catch (err, stack) {
      logger.error(tag, "$err,$stack");
      Global.showTipsDialog(text: TranslationKey.exportFailedAndViewLogs.tr, context: context);
    } finally {
      dialog.close();
      //恢复截图复制
      clipboardService.startListenScreenshot();
    }
  }

  ///恢复备份
  Future<void> restore(BuildContext context) async {
    final backupTypes = await _showBackupTypesDialog(context);
    if (backupTypes.isEmpty) {
      Global.showSnackBarWarn(text: TranslationKey.userCancelled.tr, context: context);
      return;
    }
    final backupSource = await _showBackupSourceDialog(context);
    if (backupSource == null) {
      Global.showSnackBarWarn(text: TranslationKey.userCancelled.tr, context: context);
      return;
    }
    String? localFilePath;
    StorageClient? storageClient;
    //若为存储服务，显示文件列表然后下载到临时目录执行解压，显示下载进度弹窗
    if (backupSource == BackupSource.local) {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      localFilePath = result.files[0].path!;
    } else {
      if (backupSource == BackupSource.webdav) {
        storageClient = appConfig.webDAVConfig?.toClient();
      } else {
        storageClient = appConfig.s3Config?.toClient();
      }
      if (storageClient == null) {
        var text = TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr;
        if (backupSource != BackupSource.webdav) {
          text = TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr;
        }
        Global.showTipsDialog(text: text, context: context);
        return;
      }
      late String baseDir;
      if (backupSource == BackupSource.webdav) {
        baseDir = appConfig.webDAVConfig!.baseDir;
      } else {
        baseDir = appConfig.s3Config!.baseDir;
      }
      final initPath = "$baseDir/backup";
      if (!await storageClient.isDirectory("backup")) {
        if (!await storageClient.createDirectory("backup")) {
          Global.showTipsDialog(text: TranslationKey.createFolder.tr, context: context);
          return;
        }
      }

      FileItem? selectedFile;
      late DialogController fileBrowserDialog;
      fileBrowserDialog = Global.showDialog(
        context,
        SafeArea(
          child: AlertDialog(
            title: Text(TranslationKey.selectStoragePath.tr),
            content: SizedBox(
              width: 350,
              child: FileBrowser(
                onLoadFiles: (String path) async {
                  final subPath = path.replaceFirst(baseDir, "").replaceFirst(Constants.unixDirSeparate, "");
                  final list = await storageClient!.list(path: subPath);
                  return list.where((item) => item.isDir || item.name.endsWith(".zip")).map((item) => FileItem(name: item.name, isDirectory: item.isDir, fullPath: item.path)).toList();
                },
                shouldShowUpLevel: (path) => path != baseDir || path.isNullOrEmpty,
                initialPath: initPath,
                onFileClicked: (item) {
                  selectedFile = item;
                  fileBrowserDialog.close();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => fileBrowserDialog.close(),
                child: Text(TranslationKey.dialogCancelText.tr),
              ),
            ],
          ),
        ),
      );
      await fileBrowserDialog.future;
      if (selectedFile?.fullPath == null) {
        Global.showSnackBarWarn(context: context, text: TranslationKey.userCancelled.tr);
        return;
      }
      final subPath = selectedFile!.fullPath!.replaceFirst(baseDir, "").replaceFirst(Constants.unixDirSeparate, "");
      localFilePath = "${appConfig.documentsPath}/${selectedFile!.name}".normalizePath;
      final loadingController = LoadingProgressController();
      final loadingDialog = Global.showLoadingDialog(
        context: context,
        loadingText: TranslationKey.downloading.tr,
        controller: loadingController,
      );
      final downloadResult = await storageClient.downloadFile(
        subPath,
        localFilePath,
        onProgress: (int count, int total) {
          int percentage = (count * 100 / total).toInt();
          loadingController.update(percentage, 100);
        },
      );
      await loadingDialog.close();
      if (!downloadResult) {
        Global.showTipsDialog(context: context, text: TranslationKey.downloadFailed.tr);
        return;
      }
    }
    var loadingController = LoadingProgressController();
    final dialog = Global.showLoadingDialog(
      context: context,
      dismissible: false,
      showCancel: true,
      loadingText: TranslationKey.importing.tr,
      controller: loadingController,
      onCancel: () {
        backupHandler.cancel();
      },
    );
    await Future.delayed(200.ms);
    final clipboardService = Get.find<ClipboardService>();
    try {
      //如果启用了截图复制，临时关闭
      clipboardService.stopListenScreenshot();
      final exInfo = await backupHandler.restore(File(localFilePath), loadingController, backupTypes);
      dialog.close();
      if (exInfo != null) {
        if (backupSource != BackupSource.local) {
          File(localFilePath).delete();
        }
        if (exInfo.err is UserCancelBackup) {
          Global.showSnackBarWarn(context: context, text: TranslationKey.cancelled.tr);
        } else {
          Global.showTipsDialog(context: context, title: TranslationKey.importFailed.tr, text: "$exInfo");
        }
      } else {
        Global.showTipsDialog(context: context, title: TranslationKey.importSuccess.tr, text: TranslationKey.restoreRestartPrompt.tr);
        final historyController = Get.find<HistoryController>();
        devService.init();
        tagService.init();
        historyController.refreshData();
      }
    } catch (err, stack) {
      logger.error(tag, "$err,$stack");
    } finally {
      dialog.close();
      //恢复截图复制
      clipboardService.startListenScreenshot();
    }
  }

  //endregion

  //region 屏幕关闭与唤醒监听

  @override
  void onScreenOpened() {
    if (!Platform.isAndroid) {
      return;
    }
    var currentMode = appConfig.workingMode;
    if (currentMode != EnvironmentType.shizuku && currentMode != EnvironmentType.root) {
      return;
    }
    //屏幕亮起2s内没关闭则启动监听
    _screenEventTimer?.cancel();
    _screenEventTimer = Timer(2.s, () {
      if (!appConfig.stopListeningOnScreenClosed) {
        return;
      }
      logger.debug(tag, "start listening on screen opened over 2 seconds");
      clipboardManager.startListening(
        env: appConfig.workingMode,
        way: appConfig.clipboardListeningWay,
        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
      );
    });
  }

  @override
  void onScreenUnlocked() {}

  @override
  void onScreenClosed() {
    //屏幕关闭一分钟后关闭监听
    _screenEventTimer?.cancel();
    _screenEventTimer = Timer(1.min, () {
      if (!appConfig.stopListeningOnScreenClosed) {
        return;
      }
      logger.debug(tag, "stopping listening on screen closed over 1 minutes");
      clipboardManager.stopListening();
    });
  }

  //endregion

  //endregion
}
