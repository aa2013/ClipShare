import 'dart:convert';
import 'dart:io';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/services/android_notification_listener_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/widgets/dialog/hot_key_editor_dialog.dart';
import 'package:clipshare/app/widgets/dialog/notification_server_edit_dialog.dart';
import 'package:clipshare/app/widgets/dialog/outdate_time_input_dialog.dart';
import 'package:clipshare/app/widgets/dialog/qr_image_dialog.dart';
import 'package:clipshare/app/widgets/dialog/s3_config_edit_dialog.dart';
import 'package:clipshare/app/widgets/dialog/webdav_config_edit_dialog.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/views/settings/sms_rules_setting_page.dart';
import 'package:clipshare/app/modules/views/settings/tag_rules_setting_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/clipboard_listener_way_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/translation_key_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/dot.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/environment_status_card.dart';
import 'package:clipshare/app/widgets/settings/card/clipboard_listening_way_setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:clipshare/app/widgets/settings/card/setting_header.dart';
import 'package:clipshare/app/widgets/dialog/forward_server_edit_dialog.dart';
import 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
import 'package:clipshare/app/widgets/dialog/single_select_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/enums/forward_way.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SettingsPage extends GetView<SettingsController> {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final storageService = Get.find<StorageService>();
  final logTag = "SettingsPage";
  static const arrowForwardIcon = Icon(
    Icons.arrow_forward_rounded,
    color: Colors.blueGrey,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(),
        RefreshIndicator(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: ListView(
              children: [
                //region 环境检测卡片
                if (Platform.isAndroid)
                  Obx(() {
                    return EnvironmentStatusCard(
                      icon: Obx(() => controller.envStatusIcon.value),
                      backgroundColor: controller.envStatusBgColor.value,
                      tipContent: Obx(() => controller.envStatusTipContent.value),
                      tipDesc: Obx(() => controller.envStatusTipDesc.value),
                      action: Obx(() {
                        return controller.envStatusAction.value ?? const SizedBox.shrink();
                      }),
                      onTap: controller.onEnvironmentStatusCardClick,
                    );
                  }),
                if (Platform.isAndroid)
                  Obx(
                    () => Visibility(
                      visible: appConfig.workingMode == EnvironmentType.shizuku || appConfig.workingMode == EnvironmentType.root,
                      child: SettingHeader(
                        icon: const Icon(
                          Icons.developer_mode,
                          size: 17,
                        ),
                        title: TranslationKey.clipboardListeningWay.tr,
                        tips: Tooltip(
                          message: TranslationKey.clipboardListeningWayTips.tr,
                          child: GestureDetector(
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.blueGrey,
                                size: 15,
                              ),
                            ),
                            onTap: () async {
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.clipboardListeningWayTipsDetail.tr,
                              );
                            },
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 8, left: 8),
                      ),
                    ),
                  ),
                if (Platform.isAndroid)
                  Obx(
                    () => Visibility(
                      visible: appConfig.workingMode == EnvironmentType.shizuku || appConfig.workingMode == EnvironmentType.root,
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => ClipboardListeningWaySettingCard(
                                cardMargin: const EdgeInsets.only(left: 0, right: 3),
                                icon: Icons.visibility_off,
                                name: ClipboardListeningWay.hiddenApi.tr,
                                selected: appConfig.clipboardListeningWay == ClipboardListeningWay.hiddenApi,
                                onTap: () {
                                  if (appConfig.clipboardListeningWay == ClipboardListeningWay.hiddenApi) {
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.clipboardListeningWayToggleConfirmContent.trParams({"way": ClipboardListeningWay.hiddenApi.tr}),
                                    showCancel: true,
                                    onOk: () async {
                                      appConfig.setClipboardListeningWay(ClipboardListeningWay.hiddenApi);
                                      await clipboardManager.stopListening();
                                      clipboardManager.startListening(
                                        env: appConfig.workingMode,
                                        way: ClipboardListeningWay.hiddenApi,
                                        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Obx(
                              () => ClipboardListeningWaySettingCard(
                                cardMargin: const EdgeInsets.only(right: 0, left: 3),
                                icon: Icons.list_alt,
                                name: ClipboardListeningWay.logs.tr,
                                selected: appConfig.clipboardListeningWay == ClipboardListeningWay.logs,
                                onTap: () {
                                  if (appConfig.clipboardListeningWay == ClipboardListeningWay.logs) {
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.clipboardListeningWayToggleConfirmContent.trParams({"way": ClipboardListeningWay.logs.tr}),
                                    showCancel: true,
                                    onOk: () async {
                                      appConfig.setClipboardListeningWay(ClipboardListeningWay.logs);
                                      await clipboardManager.stopListening();
                                      clipboardManager.startListening(
                                        env: appConfig.workingMode,
                                        way: ClipboardListeningWay.logs,
                                        notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                //endregion

                ///region 常规
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.commonSettingsGroupName.tr,
                    icon: const Icon(Icons.discount_outlined),
                    cardList: [
                      SettingCard(
                        title: Text(TranslationKey.commonSettingsRunAtStartup.tr),
                        value: appConfig.launchAtStartup,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) async {
                            PackageInfo packageInfo = await PackageInfo.fromPlatform();
                            final appName = packageInfo.appName;
                            final appPath = Platform.resolvedExecutable;
                            launchAtStartup.setup(
                              appName: appName,
                              appPath: appPath,
                            );
                            if (checked) {
                              await launchAtStartup.enable();
                            } else {
                              await launchAtStartup.disable();
                            }
                            appConfig.setLaunchAtStartup(checked, true);
                          },
                        ),
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.commonSettingsRunMinimize.tr),
                        value: appConfig.startMini,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            appConfig.setStartMini(checked);
                          },
                        ),
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.commonSettingsShowHistoriesFloatWindow.tr),
                        value: appConfig.showHistoryFloat,
                        action: (v) => Switch(
                          value: appConfig.showHistoryFloat,
                          onChanged: (checked) {
                            if (checked) {
                              androidChannelService.showHistoryFloatWindow();
                            } else {
                              androidChannelService.closeHistoryFloatWindow();
                            }
                            HapticFeedback.mediumImpact();
                            appConfig.setShowHistoryFloat(checked);
                          },
                        ),
                        show: (v) => Platform.isAndroid,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.commonSettingsLockHistoriesFloatWindowPosition.tr,
                        ),
                        value: appConfig.lockHistoryFloatLoc,
                        action: (v) => Switch(
                          value: appConfig.lockHistoryFloatLoc,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            androidChannelService.lockHistoryFloatLoc(
                              {"loc": checked},
                            );
                            appConfig.setLockHistoryFloatLoc(checked);
                          },
                        ),
                        show: (v) => Platform.isAndroid && appConfig.showHistoryFloat,
                      ),
                      SettingCard<ThemeMode>(
                        title: Text(TranslationKey.commonSettingsTheme.tr),
                        value: appConfig.appTheme,
                        action: (v) {
                          var icon = Icons.brightness_auto_outlined;
                          var toolTip = TranslationKey.themeAuto.name.tr;
                          if (v == ThemeMode.light) {
                            icon = Icons.light_mode_outlined;
                            toolTip = TranslationKey.themeLight.name.tr;
                          } else if (v == ThemeMode.dark) {
                            icon = Icons.dark_mode_outlined;
                            toolTip = TranslationKey.themeDark.name.tr;
                          }
                          return ThemeSwitcher(
                            builder: (switcherContext) {
                              return Tooltip(
                                message: toolTip,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Icon(icon),
                                    ),
                                  ),
                                  onTapDown: (details) async {
                                    final menu = ContextMenu(
                                      entries: ThemeMode.values.map((mode) {
                                        var icon = Icons.brightness_auto_outlined;
                                        if (mode == ThemeMode.light) {
                                          icon = Icons.light_mode_outlined;
                                        } else if (mode == ThemeMode.dark) {
                                          icon = Icons.dark_mode_outlined;
                                        }
                                        return MenuItem(
                                          label: mode.tk.name.tr,
                                          icon: icon,
                                          enabled: mode != v,
                                          onSelected: () async {
                                            await appConfig.setAppTheme(mode, switcherContext, () {
                                              final currentBg = controller.envStatusBgColor.value;
                                              if (currentBg != null) {
                                                controller.envStatusBgColor.value = controller.warningBgColor;
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                      position: details.globalPosition - const Offset(0, 50),
                                      padding: const EdgeInsets.all(8.0),
                                      borderRadius: BorderRadius.circular(8),
                                    );
                                    menu.show(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SettingCard<String?>(
                        title: Text(TranslationKey.language.tr),
                        value: appConfig.language,
                        onTap: () {
                          SingleSelectDialog.show(
                            selections: Constants.languageSelections,
                            title: Text(TranslationKey.selectLanguage.tr),
                            context: context,
                            defaultValue: appConfig.language,
                            onSelected: (selected) {
                              Future.delayed(100.ms).then(
                                (_) {
                                  appConfig.setAppLanguage(selected);
                                  Get.back();
                                },
                              );
                            },
                          );
                        },
                        padding: const EdgeInsets.all(16),
                        action: (v) {
                          for (var lg in Constants.languageSelections) {
                            if (lg.value == v) {
                              return Text(lg.label);
                            }
                          }
                          return const Text("Unknown");
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 权限
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.permissionSettingsGroupName.tr,
                    icon: const Icon(Icons.admin_panel_settings),
                    cardList: [
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsNotificationTitle.tr),
                        description: Text(TranslationKey.permissionSettingsNotificationDesc.tr),
                        value: controller.hasNotifyPerm.value,
                        action: (val) => Icon(
                          val ? Icons.check_circle : Icons.help,
                          color: val ? Colors.green : Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && !v,
                        onTap: () {
                          if (!controller.hasNotifyPerm.value) {
                            controller.notifyHandler.request();
                          }
                        },
                      ),
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsFloatTitle.tr),
                        description: Text(TranslationKey.permissionSettingsFloatDesc.tr),
                        value: controller.hasFloatPerm.value,
                        action: (val) => Icon(
                          val ? Icons.check_circle : Icons.help,
                          color: val ? Colors.green : Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && !v,
                        onTap: () {
                          if (!controller.hasFloatPerm.value) {
                            controller.floatHandler.request();
                          }
                        },
                      ),
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsBatteryOptimiseTitle.tr),
                        description: Text(TranslationKey.permissionSettingsBatteryOptimiseDesc.tr),
                        value: controller.hasIgnoreBattery.value,
                        action: (val) => Icon(
                          val ? Icons.check_circle : Icons.help,
                          color: val ? Colors.green : Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && !v,
                        onTap: () {
                          if (!controller.hasIgnoreBattery.value) {
                            controller.ignoreBatteryHandler.request();
                          }
                        },
                      ),
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsSmsTitle.tr),
                        description: Text(TranslationKey.permissionSettingsSmsDesc.tr),
                        value: controller.hasSmsReadPerm.value,
                        action: (val) => Icon(
                          val ? Icons.check_circle : Icons.help,
                          color: val ? Colors.green : Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && !v,
                        onTap: () {
                          PermissionHelper.reqAndroidReadSms();
                        },
                      ),
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsAccessibilityTitle.tr),
                        description: Text(TranslationKey.permissionSettingsAccessibilityDesc.tr),
                        value: !controller.hasAccessibilityPerm.value && appConfig.sourceRecord,
                        action: (val) => const Icon(
                          Icons.help,
                          color: Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && v,
                        onTap: () {
                          PermissionHelper.reqAndroidAccessibilityPerm();
                        },
                      ),
                      SettingCard(
                        title: Text(TranslationKey.permissionSettingsNotificationRecordTitle.tr),
                        description: Text(TranslationKey.permissionSettingsNotificationRecordDesc.tr),
                        value: (!controller.hasNotificationRecordPerm.value && appConfig.enableRecordNotification) || (controller.hasNotificationRecordPerm.value && !appConfig.enableRecordNotification),
                        action: (val) => const Icon(
                          Icons.help,
                          color: Colors.orange,
                        ),
                        show: (v) => Platform.isAndroid && v,
                        onTap: () {
                          NotificationListenerService.requestPermission();
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 偏好
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.preference.tr,
                    icon: const Icon(Icons.tune),
                    cardList: [
                      SettingCard(
                        title: Text(
                          TranslationKey.preferenceSettingsRememberWindowSize.tr,
                        ),
                        description: Text(
                          "${appConfig.rememberWindowSize ? "${TranslationKey.preferenceSettingsWindowSizeRecordValue.tr}: ${appConfig.windowSize}，" : ""}${TranslationKey.preferenceSettingsWindowSizeDefaultValue.tr}: ${Constants.defaultWindowSize}",
                        ),
                        value: appConfig.rememberWindowSize,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setRememberWindowSize(checked);
                          },
                        ),
                        show: (v) => Platform.isWindows || Platform.isMacOS,
                      ),
                      //历史记录弹窗记住上次位置
                      SettingCard(
                        title: Text(
                          TranslationKey.preferenceSettingsRecordsDialogLocation.tr,
                        ),
                        description: Text("${TranslationKey.current.tr}: ${appConfig.recordHistoryDialogPosition ? TranslationKey.rememberLastPos.tr : TranslationKey.followMousePos.tr}"),
                        value: appConfig.recordHistoryDialogPosition,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setRecordHistoryDialogPosition(checked);
                            if (checked) {
                              appConfig.setHistoryDialogPosition("");
                            }
                          },
                        ),
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.showOnRecentTasks.tr),
                        description: Text(TranslationKey.showOnRecentTasksDesc.tr),
                        value: appConfig.showOnRecentTasks,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              if (!checked) {
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.showOnRecentTasksTips.tr,
                                  showCancel: true,
                                  onOk: () {
                                    androidChannelService.showOnRecentTasks(checked).then((v) {
                                      if (v) {
                                        appConfig.setShowOnRecentTasks(checked);
                                      }
                                    });
                                  },
                                );
                              } else {
                                androidChannelService.showOnRecentTasks(checked).then((v) {
                                  if (v) {
                                    appConfig.setShowOnRecentTasks(checked);
                                  }
                                });
                              }
                            },
                          );
                        },
                        show: (v) => Platform.isAndroid,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.showMoreItemsInRow.tr),
                        description: Text(TranslationKey.showMoreItemsInRowDesc.tr),
                        value: appConfig.showMoreItemsInRow,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setShowMoreItemsInRow(checked);
                            },
                          );
                        },
                        show: (v) => true,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.closeOnSameHotKeyTitle.tr),
                        description: Text(TranslationKey.closeOnSameHotKeyDesc.tr),
                        value: appConfig.closeOnSameHotKey,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setCloseOnSameHotKey(checked);
                            },
                          );
                        },
                        show: (v) => PlatformExt.isDesktop,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 通知
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.notification.tr,
                    icon: const Icon(Icons.notifications_active_outlined),
                    cardList: [
                      SettingCard(
                        title: Text(TranslationKey.recordNotification.tr),
                        value: appConfig.enableRecordNotification,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) async {
                            HapticFeedback.mediumImpact();
                            final androidNotificationListenerService = Get.find<AndroidNotificationListenerService>();
                            if (checked) {
                              var isGranted = await NotificationListenerService.isPermissionGranted();
                              if (!isGranted) {
                                await NotificationListenerService.requestPermission();
                                isGranted = await NotificationListenerService.isPermissionGranted();
                                if (isGranted) {
                                  appConfig.setEnableRecordNotification(checked);
                                  androidNotificationListenerService.startListening();
                                }
                                return;
                              } else {
                                androidNotificationListenerService.startListening();
                              }
                            } else {
                              androidNotificationListenerService.stopListening();
                            }
                            appConfig.setEnableRecordNotification(checked);
                          },
                        ),
                        show: (v) => Platform.isAndroid,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.preferenceSettingsDevConnNotification.tr,
                        ),
                        value: appConfig.notifyOnDevConn,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setNotifyOnDevConn(checked);
                          },
                        ),
                        show: (v) => true,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.preferenceSettingsDevDisconnNotification.tr,
                        ),
                        value: appConfig.notifyOnDevDisconn,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setNotifyOnDevDisconn(checked);
                          },
                        ),
                        show: (v) => true,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.preferenceSettingsShowMobileNotificationTitle.tr),
                        description: Text(TranslationKey.preferenceSettingsShowMobileNotificationDesc.tr),
                        value: appConfig.enableShowMobileNotification,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setEnableShowMobileNotification(checked);
                          },
                        ),
                        show: (v) => PlatformExt.isDesktop,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 剪贴板设置
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.clipboardSettingsGroupName.tr,
                    icon: Icon(MdiIcons.clipboardOutline),
                    cardList: [
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.clipboardSettingsSourceRecordTitle.tr,
                              maxLines: 1,
                            ),
                            if (Platform.isAndroid)
                              Container(
                                margin: const EdgeInsets.only(left: 5),
                                child: Tooltip(
                                  message: TranslationKey.clipboardSettingsSourceRecordTitleTooltip.tr,
                                  child: GestureDetector(
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.blueGrey,
                                        size: 15,
                                      ),
                                    ),
                                    onTap: () async {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: TranslationKey.clipboardSettingsSourceRecordTitleTooltipDialogContent.tr,
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                        description: Visibility(
                          visible: Platform.isAndroid,
                          child: Text(TranslationKey.clipboardSettingsSourceRecordAndroidDesc.tr),
                        ),
                        value: appConfig.sourceRecord,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableSourceRecord(checked);
                              if (Platform.isAndroid && checked && !controller.hasAccessibilityPerm.value) {
                                //检查无障碍
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.noAccessibilityPermTips.tr,
                                  showCancel: true,
                                  okText: TranslationKey.goAuthorize.tr,
                                  onOk: () {
                                    PermissionHelper.reqAndroidAccessibilityPerm();
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitle.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(width: 5),
                            Tooltip(
                              message: TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltip.tr,
                              child: GestureDetector(
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.blueGrey,
                                    size: 15,
                                  ),
                                ),
                                onTap: () async {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltipDialogContent.tr,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        description: Text(TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc.tr),
                        value: appConfig.sourceRecordViaDumpsys,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableSourceRecordViaDumpsys(checked);
                            },
                          );
                        },
                        show: (v) => Platform.isAndroid && appConfig.sourceRecord,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 发现
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.discoveringSettingsGroupName.tr,
                    icon: const Icon(Icons.wifi),
                    cardList: [
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.discoveringSettingsLocalDeviceName.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Tooltip(
                                  message: TranslationKey.copyDeviceId.tr,
                                  child: const Icon(
                                    Icons.copy,
                                    color: Colors.blueGrey,
                                    size: 15,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                Clipboard.setData(
                                  ClipboardData(
                                    text: appConfig.devInfo.guid,
                                  ),
                                );
                                Global.showSnackBarSuc(
                                  context: context,
                                  text: TranslationKey.discoveringSettingsDeviceNameCopyTip.tr,
                                );
                              },
                            ),
                          ],
                        ),
                        description: Text(
                          "id: ${appConfig.devInfo.guid}",
                        ),
                        value: appConfig.localName,
                        action: (v) => Text(v),
                        onTap: () {
                          Global.showDialog(
                            context,
                            TextEditDialog(
                              title: TranslationKey.modifyDeviceName.tr,
                              labelText: TranslationKey.deviceName.tr,
                              initStr: appConfig.localName,
                              onOk: (str) {
                                appConfig.setLocalName(str);
                                Global.showSnackBarSuc(
                                  context: context,
                                  text: TranslationKey.modifyDeviceNameCompletedTooltip.tr,
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.port.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.discoveringSettingsPortDesc.tr),
                        value: appConfig.port,
                        action: (v) => Text(v.toString()),
                        onTap: () {
                          Global.showDialog(
                            context,
                            TextEditDialog(
                              title: TranslationKey.modifyPort.tr,
                              labelText: TranslationKey.port.tr,
                              initStr: appConfig.port.toString(),
                              verify: (str) {
                                var port = int.tryParse(str);
                                if (port == null) return false;
                                return port >= 0 && port <= 65535;
                              },
                              errorText: TranslationKey.modifyPortErrorText.tr,
                              onOk: (str) {
                                appConfig.setPort(str.toInt());
                                Global.showSnackBarSuc(
                                  context: context,
                                  text: TranslationKey.discoveringSettingsModifyPortCompletedTooltip.tr,
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.allowDiscovering.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.discoveringSettingsAllowDiscoveringDesc.tr),
                        value: appConfig.allowDiscover,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setAllowDiscover(checked);
                            sktService.disConnectAllConnections(true);
                          },
                        ),
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.discoveringSettingsOnlyForwardDiscoveringTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.discoveringSettingsOnlyForwardDiscoveringDesc.tr),
                        value: appConfig.onlyForwardMode,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setOnlyForwardMode(checked);
                          },
                        ),
                        show: (v) => !kReleaseMode,
                      ),
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.discoveringSettingsHeartbeatIntervalTitle.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Tooltip(
                              message: TranslationKey.discoveringSettingsHeartbeatIntervalTooltip.tr,
                              child: GestureDetector(
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.blueGrey,
                                    size: 15,
                                  ),
                                ),
                                onTap: () async {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.discoveringSettingsHeartbeatIntervalTooltipDialogContent.tr,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        description: Text(TranslationKey.discoveringSettingsHeartbeatIntervalDesc.tr),
                        value: appConfig.heartbeatInterval,
                        action: (v) => Text(v <= 0 ? TranslationKey.dontDetect.tr : '${v}s'),
                        onTap: () {
                          Global.showDialog(
                            context,
                            TextEditDialog(
                              title: TranslationKey.discoveringSettingsModifyHeartbeatDialogTitle.tr,
                              labelText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputLabel.tr,
                              initStr: "${appConfig.heartbeatInterval <= 0 ? '' : appConfig.heartbeatInterval}",
                              verify: (str) {
                                var port = int.tryParse(str);
                                if (port == null) return false;
                                return true;
                              },
                              errorText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputErrorText.tr,
                              onOk: (str) async {
                                await appConfig.setHeartbeatInterval(str);
                                var enable = str.toInt() > 0;
                                if (enable) {
                                  sktService.startHeartbeatTest();
                                } else {
                                  sktService.stopHeartbeatTest();
                                }
                              },
                            ),
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncAutoCloseSettingTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncAutoCloseSettingDesc.tr),
                        value: appConfig.autoCloseConnAfterScreenOff,
                        show: (v) => Platform.isAndroid,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              HapticFeedback.mediumImpact();
                              appConfig.setAutoCloseConnAfterScreenOff(checked);
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.enableAutoSyncOnScreenOpenedTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.enableAutoSyncOnScreenOpenedDesc.tr),
                        value: appConfig.enableAutoSyncOnScreenOpened,
                        show: (v) => Platform.isAndroid,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableAutoSyncOnScreenOpened(checked);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 中转
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.forwardSettingsGroupName.tr,
                    icon: const Icon(Icons.cloud_sync_outlined),
                    cardList: [
                      SettingCard<ForwardWay>(
                        title: Text(TranslationKey.forwardWay.tr),
                        value: appConfig.forwardWay,
                        action: (v) {
                          late String text;
                          if (ForwardWay.storageWays.contains(v)) {
                            text = TranslationKey.storageService.tr;
                          } else if (v == ForwardWay.server) {
                            text = TranslationKey.forwardHost.tr;
                          } else {
                            text = TranslationKey.none.tr;
                          }
                          return Tooltip(
                            message: TranslationKey.modify.tr,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                            ),
                          );
                        },
                        onTapDown: (details) {
                          final v = appConfig.forwardWay;
                          final menu = ContextMenu(
                            entries: [
                              MenuItem(
                                label: TranslationKey.forwardServer.tr,
                                icon: Icons.computer,
                                enabled: v != ForwardWay.server,
                                onSelected: () async {
                                  void setup() async {
                                    await appConfig.setForwardWay(ForwardWay.server);
                                    await storageService.stop();
                                    if (!appConfig.enableForward || appConfig.forwardServer == null) {
                                      //若无配置，关闭中转
                                      await appConfig.setEnableForward(false);
                                      return;
                                    }
                                    sktService.connectForwardServer(true);
                                  }

                                  if (appConfig.forwardWay == ForwardWay.none || !appConfig.enableForward) {
                                    setup();
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.changeForwardWayConfirm.tr,
                                    showCancel: true,
                                    onOk: setup,
                                  );
                                },
                              ),
                              MenuItem(
                                label: 'WebDAV',
                                icon: Icons.storage,
                                enabled: v != ForwardWay.webdav,
                                onSelected: () {
                                  void setup() async {
                                    await appConfig.setForwardWay(ForwardWay.webdav);
                                    await sktService.disConnectForwardServer();
                                    if (!appConfig.enableForward || appConfig.webDAVConfig == null) {
                                      //若无配置，关闭中转
                                      await appConfig.setEnableForward(false);
                                      return;
                                    }
                                    storageService.restart();
                                  }

                                  if (appConfig.forwardWay == ForwardWay.none || !appConfig.enableForward) {
                                    setup();
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.changeForwardWayConfirm.tr,
                                    showCancel: true,
                                    onOk: setup,
                                  );
                                },
                              ),
                              MenuItem(
                                label: TranslationKey.s3.tr,
                                icon: Icons.storage,
                                enabled: v != ForwardWay.s3,
                                onSelected: () async {
                                  void setup() async {
                                    await appConfig.setForwardWay(ForwardWay.s3);
                                    await sktService.disConnectForwardServer();
                                    if (!appConfig.enableForward || appConfig.s3Config == null) {
                                      //若无配置，关闭中转
                                      await appConfig.setEnableForward(false);
                                      return;
                                    }
                                    storageService.restart();
                                  }

                                  if (appConfig.forwardWay == ForwardWay.none || !appConfig.enableForward) {
                                    setup();
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.changeForwardWayConfirm.tr,
                                    showCancel: true,
                                    onOk: setup,
                                  );
                                },
                              ),
                              MenuItem(
                                label: TranslationKey.none.tr,
                                icon: Icons.cloud_off,
                                enabled: v != ForwardWay.none,
                                onSelected: () async {
                                  Future<void> setup() async {
                                    await appConfig.setEnableForward(false);
                                    await appConfig.setForwardWay(ForwardWay.none);
                                    await sktService.disConnectForwardServer();
                                    await storageService.stop();
                                  }

                                  if (!appConfig.enableForward) {
                                    setup();
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.changeForwardWayConfirm.tr,
                                    showCancel: true,
                                    onOk: () async {
                                      setup();
                                    },
                                  );
                                },
                              ),
                            ],
                            position: Offset(Get.size.width, details.globalPosition.dy - 50),
                            padding: 8.insetAll,
                            borderRadius: BorderRadius.circular(8),
                          );
                          menu.show(context);
                        },
                      ),
                      //服务状态/通知服务配置
                      if (appConfig.forwardWay != ForwardWay.none)
                        SettingCard(
                          title: Row(
                            children: [
                              Text(
                                appConfig.forwardWay == ForwardWay.server ? TranslationKey.forwardServerStatus.tr : TranslationKey.notificationServerStatus.tr,
                                maxLines: 1,
                              ),
                              if (appConfig.forwardWay != ForwardWay.server)
                                Tooltip(
                                  message: TranslationKey.tips.tr,
                                  child: GestureDetector(
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.blueGrey,
                                        size: 15,
                                      ),
                                    ),
                                    onTap: () async {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: TranslationKey.notificationServerTips.tr,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          description: Row(
                            children: [
                              Dot(
                                radius: 6.0,
                                color: controller.forwardServerStatus.value.color,
                              ),
                              const SizedBox(width: 5),
                              Text(controller.forwardServerStatus.value.tr),
                            ],
                          ),
                          value: appConfig.forwardWay == ForwardWay.server,
                          action: (isForwardServer) {
                            if (isForwardServer) {
                              return const SizedBox.shrink();
                            }
                            return TextButton(
                              onPressed: () {
                                Global.showDialog(
                                  context,
                                  NotificationServerEditDialog(
                                    title: TranslationKey.notificationServerConfigure.tr,
                                    labelText: TranslationKey.notificationServerAddress.tr,
                                    initStr: appConfig.notificationServer,
                                    hint: 'ws://',
                                    verify: (s) => s.matchRegExp(Constants.wsUrlRegex),
                                    errorText: TranslationKey.pleaseInputCorrectWsURL.tr,
                                    onOk: (result) {
                                      appConfig.setNotificationServer(result.trimEnd('/'));
                                      if (appConfig.enableForward) {
                                        storageService.reconnectWs();
                                      }
                                    },
                                  ),
                                );
                              },
                              child: Text(TranslationKey.configure.tr),
                            );
                          },
                        ),
                      //是否启用中转服务
                      if (appConfig.forwardWay != ForwardWay.none)
                        SettingCard(
                          title: Row(
                            children: [
                              Text(
                                TranslationKey.forwardSettingsForwardTitle.tr,
                                maxLines: 1,
                              ),
                              const SizedBox(width: 5),
                              if (appConfig.forwardWay == ForwardWay.server)
                                Tooltip(
                                  message: TranslationKey.forwardSettingsForwardDownloadTooltip.tr,
                                  child: GestureDetector(
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.blueGrey,
                                        size: 15,
                                      ),
                                    ),
                                    onTap: () async {
                                      Constants.forwardDownloadUrl.askOpenUrl();
                                    },
                                  ),
                                ),
                            ],
                          ),
                          description: Text(TranslationKey.forwardSettingsForwardDesc.tr),
                          value: appConfig.enableForward,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) async {
                                HapticFeedback.mediumImpact();
                                final useServer = appConfig.forwardWay == ForwardWay.server;
                                //启用中转服务器前先校验是否填写服务器地址
                                if (useServer && appConfig.forwardServer == null) {
                                  Global.showSnackBarErr(
                                    context: context,
                                    text: TranslationKey.forwardSettingsForwardEnableRequiredText.tr,
                                  );
                                  return;
                                }
                                final useWebdav = appConfig.forwardWay == ForwardWay.webdav;
                                if (useWebdav && appConfig.webDAVConfig == null) {
                                  Global.showSnackBarErr(
                                    context: context,
                                    text: TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr,
                                  );
                                  return;
                                }
                                final useS3 = appConfig.forwardWay == ForwardWay.s3;
                                if (useS3 && appConfig.s3Config == null) {
                                  Global.showSnackBarErr(
                                    context: context,
                                    text: TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr,
                                  );
                                  return;
                                }
                                await appConfig.setEnableForward(checked);
                                if (checked) {
                                  if (useServer) {
                                    sktService.connectForwardServer(true);
                                  } else {
                                    storageService.start();
                                  }
                                } else {
                                  if (useServer) {
                                    sktService.disConnectForwardServer();
                                  } else {
                                    storageService.stop();
                                  }
                                }
                              },
                            );
                          },
                        ),
                      if (appConfig.forwardWay == ForwardWay.server)
                        SettingCard(
                          title: Text(
                            TranslationKey.forwardSettingsForwardAddressTitle.tr,
                            maxLines: 1,
                          ),
                          description: Text(TranslationKey.forwardSettingsForwardAddressDesc.tr),
                          value: appConfig.forwardServer,
                          action: (v) {
                            String text = TranslationKey.change.tr;
                            if (appConfig.forwardServer == null) {
                              text = TranslationKey.configure.tr;
                            }
                            return Row(
                              children: [
                                if (appConfig.forwardServer != null)
                                  IconButton(
                                    onPressed: () {
                                      Global.showDialog(
                                        context,
                                        QrImageDialog(
                                          title: Text(TranslationKey.forwardServer.tr),
                                          data: jsonEncode(appConfig.forwardServer!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    Global.showDialog(
                                      context,
                                      ForwardServerEditDialog(
                                        initValue: v,
                                        onOk: (server) {
                                          appConfig.setForwardServer(server);
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(text),
                                ),
                              ],
                            );
                          },
                        ),
                      if (appConfig.forwardWay == ForwardWay.webdav)
                        SettingCard(
                          title: Text(
                            TranslationKey.forwardSettingsWebDAVTitle.tr,
                            maxLines: 1,
                          ),
                          description: Text(appConfig.webDAVConfig?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
                          value: appConfig.webDAVConfig,
                          action: (v) {
                            String text = TranslationKey.change.tr;
                            if (appConfig.webDAVConfig == null) {
                              text = TranslationKey.configure.tr;
                            }
                            return Row(
                              children: [
                                if (appConfig.webDAVConfig != null)
                                  IconButton(
                                    onPressed: () {
                                      Global.showDialog(
                                        context,
                                        QrImageDialog(
                                          title: const Text("WebDAV"),
                                          data: jsonEncode(appConfig.webDAVConfig!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    Global.showDialog(
                                      context,
                                      WebDAVConfigEditDialog(
                                        initValue: v,
                                        onOk: (config) {
                                          appConfig.setWebDavConfig(config);
                                          if (appConfig.enableForward) {
                                            storageService.restart();
                                          }
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(text),
                                ),
                              ],
                            );
                          },
                        ),
                      if (appConfig.forwardWay == ForwardWay.s3)
                        SettingCard(
                          title: Text(
                            TranslationKey.forwardSettingsS3Title.tr,
                            maxLines: 1,
                          ),
                          description: Text(appConfig.s3Config?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
                          value: appConfig.s3Config,
                          action: (v) {
                            String text = TranslationKey.change.tr;
                            if (appConfig.s3Config == null) {
                              text = TranslationKey.configure.tr;
                            }
                            return Row(
                              children: [
                                if (appConfig.s3Config != null)
                                  IconButton(
                                    onPressed: () {
                                      Global.showDialog(
                                        context,
                                        QrImageDialog(
                                          title: Text(TranslationKey.s3.tr),
                                          data: jsonEncode(appConfig.s3Config!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    Global.showDialog(
                                      context,
                                      S3ConfigEditDialog(
                                        initValue: v,
                                        onOk: (config) {
                                          appConfig.setS3Config(config);
                                          if (appConfig.enableForward) {
                                            storageService.restart();
                                          }
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(text),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),

                ///endregion

                ///region 安全设置
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.securitySettingsGroupName.tr,
                    icon: const Icon(Icons.fingerprint_outlined),
                    cardList: [
                      SettingCard(
                        title: Text(
                          TranslationKey.securitySettingsEnableSecurityTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.securitySettingsEnableSecurityDesc.tr),
                        value: appConfig.useAuthentication,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              if (appConfig.appPassword == null && checked) {
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                                  onOk: controller.gotoSetPwd,
                                  okText: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                                  showCancel: true,
                                );
                                appConfig.setUseAuthentication(false);
                              } else {
                                appConfig.setUseAuthentication(checked);
                              }
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.securitySettingsEnableSecurityAppPwdModifyTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(appConfig.appPassword == null ? TranslationKey.createAppPwd.tr : TranslationKey.changeAppPwd.tr),
                        value: appConfig.appPassword,
                        action: (v) {
                          return TextButton(
                            onPressed: () {
                              if (appConfig.appPassword == null) {
                                controller.gotoSetPwd();
                              } else {
                                //第一步验证
                                appConfig.authenticating.value = true;
                                final homeController = Get.find<HomeController>();
                                homeController
                                    .gotoAuthenticationPage(
                                      TranslationKey.authenticationPageTitle.tr,
                                      lock: false,
                                    )
                                    ?.then((v) {
                                      //null为正常验证，设置密码，否则主动退出
                                      if (v != null) {
                                        controller.gotoSetPwd();
                                      }
                                    });
                              }
                            },
                            child: Text(appConfig.appPassword == null ? TranslationKey.create.tr : TranslationKey.change.tr),
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.securitySettingsReverificationTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.securitySettingsReverificationDesc.tr),
                        value: appConfig.appRevalidateDuration,
                        onTap: () {
                          DialogController? dialog;
                          dialog = SingleSelectDialog.show(
                            context: context,
                            defaultValue: appConfig.appRevalidateDuration,
                            onSelected: (duration) {
                              Future.delayed(100.ms).then(
                                (value) {
                                  appConfig.setAppRevalidateDuration(duration);
                                  dialog!.close();
                                },
                              );
                            },
                            selections: Constants.authBackEndTimeSelections,
                            title: Text(TranslationKey.securitySettingsReverificationTitle.tr),
                          );
                        },
                        action: (v) {
                          var duration = appConfig.appRevalidateDuration;
                          return Text(
                            duration <= 0 ? TranslationKey.immediately.tr : TranslationKey.securitySettingsReverificationValue.trParams({"value": duration.toString()}),
                          );
                        },
                      ),
                      SettingCard<String>(
                        title: Row(
                          children: [
                            Text(TranslationKey.dhKeySettingName.tr, maxLines: 1),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Global.showTipsDialog(context: context, text: TranslationKey.dhKeySettingTips.tr);
                              },
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.blueGrey,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        description: Text(TranslationKey.dhKeySettingDesc.tr),
                        value: appConfig.dhEncryptKey,
                        action: (v) {
                          return TextButton(
                            child: Text(v.isNullOrEmpty ? TranslationKey.configure.tr : TranslationKey.change.tr),
                            onPressed: () {
                              if (appConfig.appPassword == null) {
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                                  onOk: controller.gotoSetPwd,
                                  okText: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                                  showCancel: true,
                                );
                                return;
                              }

                              //第一步验证
                              appConfig.authenticating.value = true;
                              final homeController = Get.find<HomeController>();
                              homeController
                                  .gotoAuthenticationPage(
                                    TranslationKey.authenticationPageTitle.tr,
                                    lock: false,
                                  )
                                  ?.then((v) {
                                    if (v == null) {
                                      Global.showSnackBarWarn(text: TranslationKey.authFailed.tr, context: context);
                                      return;
                                    }
                                    Global.showDialog(
                                      context,
                                      TextEditDialog(
                                        title: TranslationKey.encryptKey.tr,
                                        labelText: TranslationKey.pleaseInput.tr,
                                        initStr: appConfig.dhEncryptKey.isEmpty ? '' : appConfig.dhEncryptKey,
                                        verify: (str) {
                                          return (str.isEmpty && (appConfig.dhAesKey ?? '').isNotEmpty) || str.replaceAll('\\s+', '').length >= 8;
                                        },
                                        errorText: TranslationKey.encryptKeyErrorTip.tr,
                                        onOk: (str) async {
                                          if (str.isEmpty) {
                                            Global.showTipsDialog(
                                              context: context,
                                              text: TranslationKey.confirmClearEncryptKey.tr,
                                              showCancel: true,
                                              onOk: () async {
                                                await appConfig.setDHEncryptKey(str);
                                                Global.showSnackBarSuc(text: TranslationKey.clearSuccess.tr, context: context);
                                              },
                                            );
                                          } else {
                                            await appConfig.setDHEncryptKey(str);
                                            Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
                                          }
                                        },
                                      ),
                                    );
                                  });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 快捷键
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.hotKeySettingsGroupName.tr,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    cardList: [
                      SettingCard(
                        title: Text(
                          TranslationKey.hotKeySettingsHistoryTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.hotKeySettingsHistoryDesc.tr),
                        value: appConfig.historyWindowHotKeys,
                        action: (v) {
                          final desc = AppHotKeyHandler.getByType(HotKeyType.historyWindow)?.desc;
                          final dialog = HotKeyEditorDialog(
                            hotKeyType: HotKeyType.historyWindow,
                            initContent: desc ?? "",
                            clearable: true,
                            onDone: (hotKey, keyCodes) {
                              AppHotKeyHandler.registerHistoryWindow(hotKey)
                                  .then((v) {
                                    //设置为新值
                                    appConfig.setHistoryWindowHotKeys(keyCodes);
                                  })
                                  .catchError((err) {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                    );
                                  });
                            },
                            onClear: () {
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.clearHotKeyConfirm.tr,
                                showCancel: true,
                                onOk: () {
                                  appConfig.setHistoryWindowHotKeys("");
                                  AppHotKeyHandler.unRegister(HotKeyType.historyWindow);
                                  Get.back();
                                },
                              );
                            },
                          );
                          if (desc == null) {
                            return TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(TranslationKey.create.tr),
                            );
                          }
                          return Tooltip(
                            message: TranslationKey.modify.tr,
                            child: TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(desc),
                            ),
                          );
                        },
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.sendFile.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.hotKeySettingsFileDesc.tr),
                        value: appConfig.syncFileHotKeys,
                        action: (v) {
                          final desc = AppHotKeyHandler.getByType(HotKeyType.fileSender)?.desc;
                          final dialog = HotKeyEditorDialog(
                            hotKeyType: HotKeyType.fileSender,
                            initContent: desc ?? "",
                            clearable: true,
                            onDone: (hotKey, keyCodes) {
                              AppHotKeyHandler.registerFileSync(hotKey)
                                  .then((v) {
                                    //设置为新值
                                    appConfig.setSyncFileHotKeys(keyCodes);
                                  })
                                  .catchError((err) {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                    );
                                  });
                            },
                            onClear: () {
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.clearHotKeyConfirm.tr,
                                showCancel: true,
                                onOk: () {
                                  appConfig.setSyncFileHotKeys("");
                                  AppHotKeyHandler.unRegister(HotKeyType.fileSender);
                                  Get.back();
                                },
                              );
                            },
                          );
                          if (desc == null) {
                            return TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(TranslationKey.create.tr),
                            );
                          }
                          return Tooltip(
                            message: TranslationKey.modify.tr,
                            child: TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(desc),
                            ),
                          );
                        },
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.showMainWindow.tr),
                        value: appConfig.showMainWindowHotKeys,
                        action: (v) {
                          final desc = AppHotKeyHandler.getByType(HotKeyType.showMainWindows)?.desc;
                          final dialog = HotKeyEditorDialog(
                            hotKeyType: HotKeyType.showMainWindows,
                            initContent: desc ?? "",
                            clearable: desc != null,
                            onDone: (hotKey, keyCodes) {
                              AppHotKeyHandler.registerShowMainWindow(hotKey)
                                  .then((v) {
                                    //设置为新值
                                    appConfig.setShowMainWindowHotKeys(keyCodes);
                                    //更新托盘菜单
                                    final trayService = Get.find<TrayService>();
                                    trayService.updateTrayMenus(false);
                                  })
                                  .catchError((err) {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                    );
                                  });
                            },
                            onClear: () {
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.clearHotKeyConfirm.tr,
                                showCancel: true,
                                onOk: () {
                                  appConfig.setShowMainWindowHotKeys("");
                                  AppHotKeyHandler.unRegister(HotKeyType.showMainWindows);
                                  final trayService = Get.find<TrayService>();
                                  trayService.updateTrayMenus(false);
                                  Get.back();
                                },
                              );
                            },
                          );
                          if (desc == null) {
                            return TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(TranslationKey.create.tr),
                            );
                          }
                          return Tooltip(
                            message: TranslationKey.modify.tr,
                            child: TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(desc),
                            ),
                          );
                        },
                        show: (v) => PlatformExt.isDesktop,
                      ),
                      SettingCard(
                        title: Text(TranslationKey.exitApp.tr),
                        value: appConfig.exitAppHotKeys,
                        action: (v) {
                          final desc = AppHotKeyHandler.getByType(HotKeyType.exitApp)?.desc;
                          final dialog = HotKeyEditorDialog(
                            hotKeyType: HotKeyType.exitApp,
                            initContent: desc ?? "",
                            clearable: desc != null,
                            onDone: (hotKey, keyCodes) {
                              AppHotKeyHandler.registerExitApp(hotKey)
                                  .then((v) {
                                    //设置为新值
                                    appConfig.setExitAppHotKeys(keyCodes);
                                    //更新托盘菜单
                                    final trayService = Get.find<TrayService>();
                                    trayService.updateTrayMenus(false);
                                  })
                                  .catchError((err) {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                    );
                                  });
                            },
                            onClear: () {
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.clearHotKeyConfirm.tr,
                                showCancel: true,
                                onOk: () {
                                  appConfig.setExitAppHotKeys("");
                                  AppHotKeyHandler.unRegister(HotKeyType.exitApp);
                                  final trayService = Get.find<TrayService>();
                                  trayService.updateTrayMenus(false);
                                  Get.back();
                                },
                              );
                            },
                          );
                          if (desc == null) {
                            return TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(TranslationKey.create.tr),
                            );
                          }
                          return Tooltip(
                            message: TranslationKey.modify.tr,
                            child: TextButton(
                              onPressed: () {
                                Global.showDialog(context, dialog);
                              },
                              child: Text(desc),
                            ),
                          );
                        },
                        show: (v) => PlatformExt.isDesktop,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 同步设置
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.syncSettingsGroupName.tr,
                    icon: const Icon(Icons.sync_rounded),
                    cardList: [
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsAutoSyncMissingDataTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncSettingsAutoSyncMissingDataDesc.tr),
                        value: appConfig.autoSyncMissingData,
                        show: (v) => true,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              appConfig.setAutoSyncMissingData(checked);
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsSmsTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncSettingsSmsDesc.tr),
                        value: appConfig.enableSmsSync,
                        show: (v) => Platform.isAndroid,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              if (checked) {
                                var isGranted = await PermissionHelper.testAndroidReadSms();
                                if (isGranted) {
                                  androidChannelService.startSmsListen();
                                } else {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.syncSettingsSmsPermissionRequired.tr,
                                    okText: TranslationKey.dialogAuthorizationButtonText.tr,
                                    showCancel: true,
                                    onOk: () async {
                                      await PermissionHelper.reqAndroidReadSms();
                                      if (await PermissionHelper.testAndroidReadSms()) {
                                        appConfig.setEnableSmsSync(true);
                                        androidChannelService.startSmsListen();
                                      }
                                    },
                                  );
                                  return;
                                }
                              } else {
                                androidChannelService.stopSmsListen();
                              }
                              appConfig.setEnableSmsSync(checked);
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsStoreImg2PicturesTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncSettingsStoreImg2PicturesDesc.tr),
                        value: appConfig.saveToPictures,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              HapticFeedback.mediumImpact();
                              if (checked) {
                                var path = "${Constants.androidPicturesPath}/${Constants.appName}";
                                var res = await PermissionHelper.testAndroidStoragePerm(path);
                                if (res) {
                                  appConfig.setSaveToPictures(true);
                                  return;
                                }
                                DialogController? dialog;
                                dialog = Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.syncSettingsStoreImg2PicturesNoPermText.tr,
                                  showCancel: true,
                                  onOk: () async {
                                    await dialog!.close();
                                    await PermissionHelper.reqAndroidStoragePerm(path);
                                    if (!await PermissionHelper.testAndroidStoragePerm(path)) {
                                      appConfig.setSaveToPictures(false);
                                      Global.showTipsDialog(
                                        context: context,
                                        text: TranslationKey.syncSettingsStoreImg2PicturesCancelPerm.tr,
                                      );
                                    } else {
                                      //授权成功
                                      appConfig.setSaveToPictures(true);
                                    }
                                  },
                                  okText: TranslationKey.dialogAuthorizationButtonText.tr,
                                );
                              } else {
                                appConfig.setSaveToPictures(false);
                              }
                            },
                          );
                        },
                        show: (v) => Platform.isAndroid,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsStoreFilePathTitle.tr,
                          maxLines: 1,
                        ),
                        description: Visibility(
                          visible: PlatformExt.isDesktop,
                          replacement: Text(appConfig.fileStorePath),
                          child: Tooltip(
                            message: TranslationKey.doubleClick2OpenPath.tr,
                            child: Text(appConfig.fileStorePath),
                          ),
                        ),
                        value: false,
                        action: (v) {
                          return TextButton(
                            onPressed: () async {
                              String? directory = await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
                              if (directory != null) {
                                if (!FileUtil.testWriteable(directory)) {
                                  Global.showTipsDialog(context: context, text: TranslationKey.unWriteablePathTips.tr);
                                  return;
                                }
                                appConfig.setFileStorePath(directory);
                              }
                            },
                            child: Text(
                              TranslationKey.selection.tr,
                              maxLines: 1,
                            ),
                          );
                        },
                        onDoubleTap: () async {
                          final dir = Directory(appConfig.fileStorePath);
                          if (!await dir.exists()) {
                            await dir.create(recursive: true);
                          }
                          await OpenFile.open(
                            appConfig.fileStorePath,
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsAutoCopyImgTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncSettingsAutoCopyImgDesc.tr),
                        show: (v) => true,
                        value: appConfig.autoCopyImageAfterSync,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              appConfig.setAutoCopyImageAfterSync(checked);
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.syncSettingsAutoCopyScreenShotTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.syncSettingsAutoCopyScreenShotDesc.tr),
                        show: (v) => Platform.isAndroid,
                        value: appConfig.autoCopyImageAfterScreenShot,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) async {
                              appConfig.setAutoCopyImageAfterScreenShot(checked);
                              final clipboardService = Get.find<ClipboardService>();
                              if (checked) {
                                clipboardService.startListenScreenshot();
                              } else {
                                clipboardService.stopListenScreenshot();
                              }
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.cleanData.tr,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        value: null,
                        action: (v) => IconButton(
                          onPressed: controller.gotoCleanDataPage,
                          icon: arrowForwardIcon,
                        ),
                        onTap: controller.gotoCleanDataPage,
                      ),
                      SettingCard<int>(
                        title: Text(TranslationKey.syncOutDateSettingTitle.tr),
                        description: Text(TranslationKey.syncOutDateSettingDesc.tr),
                        value: appConfig.syncOutdateLimitTime,
                        action: (v) => Text(v == 0 ? TranslationKey.noLimits.tr : v.timeSpanStr),
                        onTap: () {
                          Global.showDialog(
                            context,
                            OutdateTimeInputDialog(
                              initValue: appConfig.syncOutdateLimitTime,
                              onConfirm: (value) {
                                appConfig.setNewPairedDeviceSyncOldDataLimitTime(value);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 规则设置
                SettingCardGroup(
                  groupName: TranslationKey.ruleSettingsGroupName.tr,
                  icon: const Icon(Icons.assignment_outlined),
                  cardList: [
                    SettingCard(
                      title: Text(
                        TranslationKey.ruleSettingsTagRuleTitle.tr,
                        maxLines: 1,
                      ),
                      description: Text(TranslationKey.ruleSettingsTagRuleDesc.tr),
                      value: false,
                      action: (v) {
                        return TextButton(
                          onPressed: () {
                            var page = TagRuleSettingPage();
                            if (appConfig.isSmallScreen) {
                              Get.to(page);
                            } else {
                              Global.showDialog(
                                context,
                                DynamicSizeWidget(
                                  child: page,
                                ),
                              );
                            }
                          },
                          child: Text(TranslationKey.configure.tr),
                        );
                      },
                    ),
                    SettingCard(
                      title: Text(
                        TranslationKey.ruleSettingsSmsRuleTitle.tr,
                        maxLines: 1,
                      ),
                      description: Text(TranslationKey.ruleSettingsSmsRuleDesc.tr),
                      value: false,
                      show: (v) => Platform.isAndroid,
                      action: (v) {
                        return TextButton(
                          onPressed: () {
                            var page = SmsRuleSettingPage();
                            if (appConfig.isSmallScreen) {
                              Get.to(page);
                            } else {
                              Global.showDialog(
                                context,
                                DynamicSizeWidget(
                                  child: page,
                                ),
                              );
                            }
                          },
                          child: Text(TranslationKey.configure.tr),
                        );
                      },
                    ),
                    SettingCard(
                      title: Text(
                        TranslationKey.blacklistRules.tr,
                        maxLines: 1,
                      ),
                      value: false,
                      action: (v) => IconButton(
                        onPressed: controller.gotoBlackListPage,
                        icon: arrowForwardIcon,
                      ),
                      onTap: controller.gotoBlackListPage,
                    ),
                    SettingCard(
                      title: Text(
                        TranslationKey.notificationRules.tr,
                        maxLines: 1,
                      ),
                      value: null,
                      action: (v) => IconButton(
                        onPressed: controller.gotoFilterRuleListPage,
                        icon: arrowForwardIcon,
                      ),
                      onTap: controller.gotoFilterRuleListPage,
                      show: (_) => Platform.isAndroid,
                    ),
                  ],
                ),

                ///endregion

                ///region 日志
                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.logSettingsGroupName.tr,
                    icon: const Icon(Icons.bug_report_outlined),
                    cardList: [
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.logSettingsEnableTitle.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Tooltip(
                              message: TranslationKey.openFolder.tr,
                              child: GestureDetector(
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    Icons.open_in_new_outlined,
                                    color: Colors.blueGrey,
                                    size: 17,
                                  ),
                                ),
                                onTap: () async {
                                  Directory(appConfig.logsDirPath).createSync(recursive: true);
                                  try {
                                    await OpenFile.open(appConfig.logsDirPath);
                                  } catch (e) {
                                    Log.error(logTag, e);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        description: Obx(() {
                          final tmp = controller.updater;
                          final emptyStr = tmp.value != 0 ? "" : "";
                          final size = FileUtil.getDirectorySize(appConfig.logsDirPath);
                          return Text(
                            "${TranslationKey.logSettingsEnableDesc.trParams({
                              "size": size.sizeStr,
                            })}$emptyStr",
                          );
                        }),
                        value: appConfig.enableLogsRecord,
                        onTap: () {
                          controller.gotoLogPage();
                        },
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableLogsRecord(checked);
                              if (!checked) {
                                late DialogController dialog;
                                dialog = Global.showDialog(
                                  context,
                                  AlertDialog(
                                    title: Text(TranslationKey.tips.tr),
                                    content: Text(TranslationKey.logSettingsAckDelLogFiles.tr),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          dialog.close();
                                        },
                                        child: Text(TranslationKey.dialogCancelText.tr),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          FileUtil.deleteDirectoryFiles(
                                            appConfig.logsDirPath,
                                          );
                                          controller.updater.value++;
                                          dialog.close();
                                        },
                                        child: Text(TranslationKey.dialogConfirmText.tr),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.logSettingsAutoUploadCrashLogTitle.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Global.showTipsDialog(context: context, text: TranslationKey.logSettingsAutoUploadCrashLogTips.tr);
                              },
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.blueGrey,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        description: Text(TranslationKey.logSettingsAutoUploadCrashLogDesc.tr),
                        value: appConfig.enableAutoUploadCrashLogs,
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableAutoUploadCrashLogs(checked);
                              androidChannelService.setAutoReportCrashes(checked);
                            },
                          );
                        },
                        show: (v) => Platform.isAndroid,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 统计分析
                SettingCardGroup(
                  groupName: TranslationKey.statisticsSettingsGroupName.tr,
                  icon: const Icon(Icons.bar_chart),
                  cardList: [
                    SettingCard(
                      title: Text(
                        TranslationKey.statisticsSettingsTitle.tr,
                        maxLines: 1,
                      ),
                      description: Text(TranslationKey.statisticsSettingsDesc.tr),
                      value: null,
                      onTap: () {
                        controller.gotoStatisticPage();
                      },
                      action: (v) => IconButton(
                        onPressed: () {
                          controller.gotoStatisticPage();
                        },
                        icon: const Icon(
                          Icons.bar_chart,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                ///endregion

                ///region 备份和恢复
                SettingCardGroup(
                  groupName: TranslationKey.backupRestore.tr,
                  icon: Icon(MdiIcons.backupRestore),
                  cardList: [
                    SettingCard(
                      title: Text(TranslationKey.backup.tr),
                      description: Text(TranslationKey.backupSettingDesc.tr),
                      value: null,
                      action: (v) {
                        return TextButton(
                          onPressed: () => controller.startBackup(context),
                          child: Text(TranslationKey.startUp.tr),
                        );
                      },
                    ),
                    SettingCard(
                      title: Text(TranslationKey.restore.tr),
                      description: Text(TranslationKey.restoreSettingDesc.tr),
                      value: null,
                      action: (v) {
                        return TextButton(
                          onPressed: () => controller.restore(context),
                          child: Text(TranslationKey.selection.tr),
                        );
                      },
                    ),
                  ],
                ),

                ///endregion

                ///region 关于
                SettingCardGroup(
                  groupName: TranslationKey.about.tr,
                  icon: const Icon(Icons.info_outline),
                  cardList: [
                    SettingCard(
                      title: Row(
                        children: [
                          Text(
                            "${TranslationKey.about.tr} ${Constants.appName}",
                            maxLines: 1,
                          ),
                        ],
                      ),
                      value: null,
                      action: (v) => IconButton(
                        onPressed: () {
                          controller.gotoAboutPage();
                        },
                        icon: arrowForwardIcon,
                      ),
                      onTap: () {
                        controller.gotoAboutPage();
                      },
                    ),
                  ],
                ),

                ///endregion
                const SizedBox(height: 10),
              ],
            ),
          ),
          onRefresh: () {
            controller.update();
            return Future.value();
          },
        ),
      ],
    );
  }
}
