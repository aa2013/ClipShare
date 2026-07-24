import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/windows_win_v_takeover.dart';
import 'dart:async';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/dialog/hot_key_editor_dialog.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_section_view_base.dart';

class SettingsHotKeyPage extends SettingsSectionView {
  SettingsHotKeyPage({super.key, super.embedded}) : super(section: SettingsSection.hotKey);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: false,
          cardList: buildWinVTakeOverEntries(context),
        ),
      ),
      if(Platform.isWindows) const SizedBox(height: 12),
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.hotKeySettingsGroupName.tr,
          icon: const Icon(Icons.keyboard_alt_outlined),
          cardList: buildSettingEntries(context),
        ),
      ),
    ];
  }

  /// 构建 Win+V 接管入口，保持原有确认弹窗与系统级联动行为。
  List<SettingEntry> buildWinVTakeOverEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.clipboardSettingsTakeOverWinVTitle,
          TranslationKey.clipboardSettingsTakeOverWinVDesc,
          TranslationKey.clipboardSettingsTakeOverWinVInfoDialogContent,
          TranslationKey.clipboardSettingsTakeOverWinVDialogContent,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.clipboardSettingsTakeOverWinVTitle.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: TranslationKey.explain.tr,
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
                    text: TranslationKey.clipboardSettingsTakeOverWinVInfoDialogContent.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.clipboardSettingsTakeOverWinVDesc.tr),
        value: appConfig.takeOverWinV,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              HapticFeedback.mediumImpact();
              if (checked) {
                Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.clipboardSettingsTakeOverWinVDialogContent.tr,
                  showCancel: true,
                  onOk: () async {
                    await _enableWinVTakeover(context);
                  },
                );
                return;
              }
              await _disableWinVTakeover(context);
            },
          );
        },
        show: (v) => Platform.isWindows,
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
            SettingCard(
              searchKeys: const [
                TranslationKey.hotKeySettingsHistoryTitle,
                TranslationKey.hotKeySettingsHistoryDesc,
                TranslationKey.hotKeySettingsHistoryTakeOverWinVTooltip,
              ],
              title: Text(
                TranslationKey.hotKeySettingsHistoryTitle.tr,
                maxLines: 1,
              ),
              description: Text(TranslationKey.hotKeySettingsHistoryDesc.tr),
              value: appConfig.historyWindowHotKeys,
              action: (v) {
                return Obx((){
                  if (appConfig.takeOverWinV) {
                    return Tooltip(
                      message: TranslationKey.hotKeySettingsHistoryTakeOverWinVTooltip.tr,
                      child: const Text(
                        Constants.winVHotKeyLabel,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
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
                });
              },
              show: (v) => PlatformExt.isDesktop,
            ),
            SettingCard(
              searchKeys: const [
                TranslationKey.sendFile,
                TranslationKey.hotKeySettingsFileDesc,
              ],
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
              searchKeys: const [TranslationKey.showMainWindow],
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
              searchKeys: const [TranslationKey.exitApp],
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
    ];
  }

  /// 开启 Win+V 接管后立即写入注册表，并注册固定的历史弹窗快捷键。
  Future<void> _enableWinVTakeover(BuildContext context) async {
    final dialog = Global.showLoadingDialog(
      context: context,
      loadingText: TranslationKey.applyingSettings.tr,
    );
    try {
      final changed = await takeOverWinV();
      if (changed) {
        await restartExplorer();
      }
      final hotKey = AppHotKeyHandler.toSystemHotKey(Constants.winVHistoryWindowKeys);
      await AppHotKeyHandler.registerHistoryWindow(hotKey);
      await appConfig.setTakeOverWinV(true);
    } catch (err, stack) {
      logger.error(logTag, err, stack);
      if (!context.mounted) {
        return;
      }
      Global.showTipsDialog(
        context: context,
        title: TranslationKey.errorDialogTitle.tr,
        text: err.toString(),
      );
    } finally {
      dialog.close();
    }
  }

  /// 关闭 Win+V 接管后恢复注册表，并回到用户原本保存的历史弹窗快捷键。
  Future<void> _disableWinVTakeover(BuildContext context) async {
    final dialog = Global.showLoadingDialog(
      context: context,
      loadingText: TranslationKey.applyingSettings.tr,
    );
    try {
      final changed = await restoreWinV();
      if (changed) {
        await restartExplorer();
      }
      if (appConfig.historyWindowHotKeys.isNotEmpty) {
        final hotKey = AppHotKeyHandler.toSystemHotKey(appConfig.historyWindowHotKeys);
        await AppHotKeyHandler.registerHistoryWindow(hotKey);
      } else {
        await AppHotKeyHandler.unRegister(HotKeyType.historyWindow);
      }
      await appConfig.setTakeOverWinV(false);
    } catch (err, stack) {
      logger.error(logTag, err, stack);
      if (!context.mounted) {
        return;
      }
      Global.showTipsDialog(
        context: context,
        title: TranslationKey.errorDialogTitle.tr,
        text: err.toString(),
      );
    } finally {
      dialog.close();
    }
  }
}
