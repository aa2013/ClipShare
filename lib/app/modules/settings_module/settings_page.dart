import 'dart:io';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/log_module/log_page.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/views/settings/sms_rules_setting_page.dart';
import 'package:clipshare/app/modules/views/settings/tag_rules_setting_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
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
import 'package:clipshare/app/widgets/hot_key_editor.dart';
import 'package:clipshare/app/widgets/settings/card/clipboard_listening_way_setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:clipshare/app/widgets/settings/card/setting_header.dart';
import 'package:clipshare/app/widgets/settings/forward_server_edit_dialog.dart';
import 'package:clipshare/app/widgets/settings/text_edit_dialog.dart';
import 'package:clipshare/app/widgets/single_select_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SettingsPage extends GetView<SettingsController> {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final logTag = "SettingsPage";

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
                        show: (v) => Platform.isWindows || Platform.isLinux,
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
                          return ThemeSwitcher(builder: (switcherContext) {
                            return PopupMenuButton<ThemeMode>(
                              icon: Icon(icon),
                              tooltip: toolTip,
                              itemBuilder: (BuildContext context) {
                                return ThemeMode.values.map(
                                  (mode) {
                                    var icon = Icons.brightness_auto_outlined;
                                    if (mode == ThemeMode.light) {
                                      icon = Icons.light_mode_outlined;
                                    } else if (mode == ThemeMode.dark) {
                                      icon = Icons.dark_mode_outlined;
                                    }
                                    return PopupMenuItem<ThemeMode>(
                                      value: mode,
                                      child: Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Icon(icon),
                                          ),
                                          Text(mode.tk.name.tr),
                                        ],
                                      ),
                                    );
                                  },
                                ).toList();
                              },
                              onSelected: (mode) async {
                                await appConfig.setAppTheme(mode, switcherContext, () {
                                  final currentBg = controller.envStatusBgColor.value;
                                  if (currentBg != null) {
                                    controller.envStatusBgColor.value = controller.warningBgColor;
                                  }
                                });
                              },
                            );
                          });
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
                              Future.delayed(
                                const Duration(milliseconds: 100),
                              ).then(
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
                        description: Text(TranslationKey.permissionSettingsAccessibilityTitle.tr),
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
                          showDialog(
                            context: context,
                            builder: (ctx) => TextEditDialog(
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
                          showDialog(
                            context: context,
                            builder: (ctx) => TextEditDialog(
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
                          showDialog(
                            context: context,
                            builder: (ctx) => TextEditDialog(
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
                      SettingCard(
                        title: Text(
                          TranslationKey.forwardServerStatus.tr,
                          maxLines: 1,
                        ),
                        description: Row(
                          children: [
                            Dot(
                              radius: 6.0,
                              color: controller.forwardServerConnected.value ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(controller.forwardServerConnected.value ? TranslationKey.connected.tr : TranslationKey.disconnected.tr),
                          ],
                        ),
                        value: appConfig.enableForward,
                      ),
                      SettingCard(
                        title: Row(
                          children: [
                            Text(
                              TranslationKey.forwardSettingsForwardTitle.tr,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
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
                              //启用中转服务器前先校验是否填写服务器地址
                              if (appConfig.forwardServer == null) {
                                Global.showSnackBarErr(
                                  context: context,
                                  text: TranslationKey.forwardSettingsForwardEnableRequiredText.tr,
                                );
                                return;
                              }
                              await appConfig.setEnableForward(checked);
                              if (checked) {
                                sktService.connectForwardServer(true);
                              } else {
                                sktService.disConnectForwardServer();
                              }
                            },
                          );
                        },
                      ),
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
                          return TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return ForwardServerEditDialog(
                                    initValue: v,
                                    onOk: (server) {
                                      appConfig.setForwardServer(server);
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(text),
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
                        show: (v) => true,
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
                            child: Text(
                              appConfig.appPassword == null ? TranslationKey.create.tr : TranslationKey.change.tr,
                            ),
                          );
                        },
                        show: (v) => true,
                      ),
                      SettingCard(
                        title: Text(
                          TranslationKey.securitySettingsReverificationTitle.tr,
                          maxLines: 1,
                        ),
                        description: Text(TranslationKey.securitySettingsReverificationDesc.tr),
                        value: appConfig.appRevalidateDuration,
                        onTap: () {
                          SingleSelectDialog.show(
                            context: context,
                            defaultValue: appConfig.appRevalidateDuration,
                            onSelected: (duration) {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                              ).then(
                                (value) {
                                  appConfig.setAppRevalidateDuration(duration);
                                  Navigator.pop(context);
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
                        show: (v) => true,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 快捷键

                Obx(() => SettingCardGroup(
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
                            var keyText = HotKeyEditor.toText(v);
                            return HotKeyEditor(
                              hotKey: keyText,
                              onDone: (modifiers, key, showText, keyCodes) {
                                if (showText == keyText) return;
                                if (modifiers.isEmpty || key == null) {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.hotKeySettingsCombinationInvalidText.tr,
                                  );
                                } else {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.hotKeySettingsSaveKeysDialogText.trParams({"keys": showText}),
                                    showCancel: true,
                                    onOk: () {
                                      var hotkey = AppHotKeyHandler.toSystemHotKey(
                                        keyCodes,
                                      );
                                      AppHotKeyHandler.registerHistoryWindow(
                                        hotkey,
                                      ).then((v) {
                                        //设置为新值
                                        appConfig.setHistoryWindowHotKeys(keyCodes);
                                      }).catchError((err) {
                                        Global.showTipsDialog(
                                          context: context,
                                          text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                        );
                                        //设置为原始值
                                        appConfig.setHistoryWindowHotKeys(
                                          appConfig.historyWindowHotKeys,
                                        );
                                      });
                                    },
                                    onCancel: () {
                                      //设置为原始值
                                      appConfig.setHistoryWindowHotKeys(
                                        appConfig.historyWindowHotKeys,
                                      );
                                    },
                                  );
                                }
                              },
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
                            var keyText = HotKeyEditor.toText(v);
                            return HotKeyEditor(
                              hotKey: keyText,
                              onDone: (modifiers, key, showText, keyCodes) {
                                if (showText == keyText) return;
                                if (modifiers.isEmpty || key == null) {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.hotKeySettingsCombinationInvalidText.tr,
                                  );
                                } else {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: TranslationKey.hotKeySettingsSaveKeysDialogText.trParams({"keys": showText}),
                                    showCancel: true,
                                    onOk: () {
                                      var hotkey = AppHotKeyHandler.toSystemHotKey(
                                        keyCodes,
                                      );
                                      AppHotKeyHandler.registerFileSync(
                                        hotkey,
                                      ).then((v) {
                                        //设置为新值
                                        appConfig.setSyncFileHotKeys(keyCodes);
                                      }).catchError((err) {
                                        Global.showTipsDialog(
                                          context: context,
                                          text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({"err": err}),
                                        );
                                        //设置为原始值
                                        appConfig.setSyncFileHotKeys(
                                          appConfig.syncFileHotKeys,
                                        );
                                      });
                                    },
                                    onCancel: () {
                                      //设置为原始值
                                      appConfig.setSyncFileHotKeys(
                                        appConfig.syncFileHotKeys,
                                      );
                                    },
                                  );
                                }
                              },
                            );
                          },
                          show: (v) => PlatformExt.isDesktop,
                        ),
                      ],
                    )),

                ///endregion

                ///region 同步设置

                Obx(
                  () => SettingCardGroup(
                    groupName: TranslationKey.syncSettingsGroupName.tr,
                    icon: const Icon(Icons.sync_rounded),
                    cardList: [
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
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.syncSettingsStoreImg2PicturesNoPermText.tr,
                                  showCancel: true,
                                  onOk: () async {
                                    Navigator.pop(context);
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
                        description: Text(appConfig.fileStorePath),
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
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.blueGrey,
                          ),
                        ),
                        onTap: controller.gotoCleanDataPage,
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
                              Get.dialog(
                                DynamicSizeWidget(
                                  child: page,
                                ),
                                barrierDismissible: false,
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
                      show: (v) => Platform.isAndroid || true,
                      action: (v) {
                        return TextButton(
                          onPressed: () {
                            var page = SmsRuleSettingPage();
                            if (appConfig.isSmallScreen) {
                              Get.to(page);
                            } else {
                              Get.dialog(
                                DynamicSizeWidget(
                                  child: page,
                                ),
                                barrierDismissible: false,
                              );
                            }
                          },
                          child: Text(TranslationKey.configure.tr),
                        );
                      },
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
                                  Directory(appConfig.logsDirPath).createSync();
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
                          if (appConfig.isSmallScreen) {
                            Get.toNamed(Routes.LOG);
                          } else {
                            Get.put(LogController());
                            Get.dialog(
                              DynamicSizeWidget(
                                child: LogPage(),
                              ),
                            ).then((_) => Get.delete<LogController>());
                          }
                        },
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableLogsRecord(checked);
                              if (!checked) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(TranslationKey.tips.tr),
                                      content: Text(TranslationKey.logSettingsAckDelLogFiles.tr),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(TranslationKey.dialogCancelText.tr),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            FileUtil.deleteDirectoryFiles(
                                              appConfig.logsDirPath,
                                            );
                                            controller.updater.value++;
                                            Navigator.pop(context);
                                          },
                                          child: Text(TranslationKey.dialogConfirmText.tr),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                          );
                        },
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
                        Get.toNamed(Routes.STATISTICS);
                      },
                      action: (v) => IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.STATISTICS);
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
                          Get.toNamed(Routes.ABOUT);
                        },
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.blueGrey,
                        ),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.ABOUT);
                      },
                    ),
                  ],
                ),

                ///endregion
                const SizedBox(
                  height: 10,
                ),
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
