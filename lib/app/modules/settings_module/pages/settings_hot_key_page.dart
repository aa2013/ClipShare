import 'settings_section_view_base.dart';

class SettingsHotKeyPage extends SettingsSectionView {
  SettingsHotKeyPage({super.key, super.embedded}) : super(section: SettingsSection.hotKey);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
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

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
            SettingCard(
              searchKeys: const [
                TranslationKey.hotKeySettingsHistoryTitle,
                TranslationKey.hotKeySettingsHistoryDesc,
              ],
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
}
