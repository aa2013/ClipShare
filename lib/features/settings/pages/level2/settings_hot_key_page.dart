import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/desktop/hotkey/hot_key_provider.dart';
import 'package:clipshare/core/platform/desktop/hotkey/windows_win_v_takeover.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_provider.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/enums/hot_key_type.dart';
import 'package:clipshare/shared/extensions/keyboard_key_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/hotkey_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/dialogs/hot_key_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _tag = 'SettingsHotKeyPage';

class SettingsHotKeyPage extends SettingsSectionView {
  const SettingsHotKeyPage({super.key, super.embedded}) : super(section: SettingsSection.hotKey);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: false,
        cardList: buildWinVTakeOverEntries(context, ref),
      ),
      if (isWindows) const SizedBox(height: 12),
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.hotKeySettingsGroupName.tr,
        icon: const Icon(Icons.keyboard_alt_outlined),
        cardList: buildHotKeyEntries(context, ref),
      ),
    ];
  }

  /// 构建 Win+V 接管入口和退出恢复选项，保持系统热键改动集中在同一组。
  List<SettingEntry> buildWinVTakeOverEntries(BuildContext context, WidgetRef ref) {
    final hotkeySettings = ref.watch(hotkeySettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.clipboardSettingsTakeOverWinVTitle,
          TranslationKey.clipboardSettingsTakeOverWinVDesc,
          TranslationKey.clipboardSettingsTakeOverWinVDialogContent,
        ],
        title: Text(
          TranslationKey.clipboardSettingsTakeOverWinVTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.clipboardSettingsTakeOverWinVDesc.tr),
        value: hotkeySettings.takeOverWinV,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              if (!context.mounted) {
                return;
              }
              if (checked) {
                await dialogManager.tips(
                  context,
                  text: TranslationKey.clipboardSettingsTakeOverWinVDialogContent.tr,
                  actions: DialogActions(
                    cancel: const DialogAction(),
                    confirm: DialogAction(
                      onPressed: () async {
                        await _enableWinVTakeover(context, ref);
                      },
                    ),
                  ),
                );
                return;
              }
              await _disableWinVTakeover(context, ref);
            },
          );
        },
        show: (v) => isWindows,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.clipboardSettingsRestoreWinVOnExitTitle,
          TranslationKey.clipboardSettingsRestoreWinVOnExitDesc,
        ],
        title: Text(
          TranslationKey.clipboardSettingsRestoreWinVOnExitTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.clipboardSettingsRestoreWinVOnExitDesc.tr),
        value: hotkeySettings.restoreWinVOnExit,
        action: (v) {
          // 只有实际接管 Win+V 后才允许配置退出恢复
          final canConfigureRestore = hotkeySettings.takeOverWinV;
          return Switch(
            value: v,
            onChanged: canConfigureRestore
                ? (checked) async {
                    HapticFeedback.mediumImpact();
                    await configDao.addOrUpdate(ConfigKey.restoreWinVOnExit, checked.toString());
                    ref.invalidate(hotkeySettingsProvider);
                  }
                : null,
          );
        },
        show: (v) => isWindows,
      ),
    ];
  }

  List<SettingEntry> buildHotKeyEntries(BuildContext context, WidgetRef ref) {
    final hotkeySettings = ref.watch(hotkeySettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
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
        value: hotkeySettings.historyWindowHotKeys,
        action: (v) {
          if (hotkeySettings.takeOverWinV) {
            return Tooltip(
              message: TranslationKey.hotKeySettingsHistoryTakeOverWinVTooltip.tr,
              child: const Text(
                winVHotKeyLabel,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          final hotKeyService = ref.read(hotKeyProvider.notifier);
          final desc = hotKeyService.getByType(HotKeyType.historyWindow)?.desc;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.historyWindow,
            initContent: desc ?? '',
            clearable: true,
            onDone: (hotKey, keyCodes) {
              hotKeyService.registerHistoryWindow(hotKey)
                  .then((v) async {
                //设置为新值
                await configDao.addOrUpdate(ConfigKey.historyWindowHotKeys, keyCodes);
                ref.invalidate(hotkeySettingsProvider);
              })
                  .catchError((err) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(
                  context,
                  text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err}),
                );
              });
            },
            onClear: () {
              dialogManager.tips(
                context,
                text: TranslationKey.clearHotKeyConfirm.tr,
                actions: DialogActions(
                  cancel: const DialogAction(),
                  confirm: DialogAction(
                    onPressed: () async {
                      await configDao.addOrUpdate(ConfigKey.historyWindowHotKeys, '');
                      ref.invalidate(hotkeySettingsProvider);
                      hotKeyService.unRegister(HotKeyType.historyWindow);
                    },
                  ),
                ),
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(desc),
            ),
          );
        },
        show: (v) => isDesktop,
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
        value: hotkeySettings.syncFileHotKeys,
        action: (v) {
          final hotKeyService = ref.read(hotKeyProvider.notifier);
          final desc = hotKeyService.getByType(HotKeyType.fileSender)?.desc;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.fileSender,
            initContent: desc ?? '',
            clearable: true,
            onDone: (hotKey, keyCodes) {
              hotKeyService.registerFileSync(hotKey)
                  .then((v) async {
                //设置为新值
                await configDao.addOrUpdate(ConfigKey.syncFileHotKeys, keyCodes);
                ref.invalidate(hotkeySettingsProvider);
              })
                  .catchError((err) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(
                  context,
                  text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err}),
                );
              });
            },
            onClear: () {
              dialogManager.tips(
                context,
                text: TranslationKey.clearHotKeyConfirm.tr,
                actions: DialogActions(
                  cancel: const DialogAction(),
                  confirm: DialogAction(
                    onPressed: () async {
                      await configDao.addOrUpdate(ConfigKey.syncFileHotKeys, '');
                      ref.invalidate(hotkeySettingsProvider);
                      hotKeyService.unRegister(HotKeyType.fileSender);
                    },
                  ),
                ),
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(desc),
            ),
          );
        },
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [TranslationKey.showMainWindow],
        title: Text(TranslationKey.showMainWindow.tr),
        value: hotkeySettings.showMainWindows,
        action: (v) {
          final hotKeyService = ref.read(hotKeyProvider.notifier);
          final desc = hotKeyService.getByType(HotKeyType.showMainWindows)?.desc;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.showMainWindows,
            initContent: desc ?? '',
            clearable: desc != null,
            onDone: (hotKey, keyCodes) {
              hotKeyService.registerShowMainWindow(hotKey)
                  .then((v) async {
                //设置为新值
                await configDao.addOrUpdate(ConfigKey.showMainWindowHotKeys, keyCodes);
                ref.invalidate(hotkeySettingsProvider);
                //更新托盘菜单
                final tray = ref.read(trayProvider.notifier);
                await tray.updateTrayMenus(false);
              })
                  .catchError((err) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(
                  context,
                  text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err}),
                );
              });
            },
            onClear: () {
              dialogManager.tips(
                context,
                text: TranslationKey.clearHotKeyConfirm.tr,
                actions: DialogActions(
                  cancel: const DialogAction(),
                  confirm: DialogAction(
                    onPressed: () async {
                      await configDao.addOrUpdate(ConfigKey.showMainWindowHotKeys, '');
                      ref.invalidate(hotkeySettingsProvider);
                      hotKeyService.unRegister(HotKeyType.showMainWindows);
                      final tray = ref.read(trayProvider.notifier);
                      await tray.updateTrayMenus(false);
                    },
                  ),
                ),
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(desc),
            ),
          );
        },
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [TranslationKey.exitApp],
        title: Text(TranslationKey.exitApp.tr),
        value: hotkeySettings.exitAppHotKeys,
        action: (v) {
          final hotKeyService = ref.read(hotKeyProvider.notifier);
          final desc = hotKeyService.getByType(HotKeyType.exitApp)?.desc;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.exitApp,
            initContent: desc ?? '',
            clearable: desc != null,
            onDone: (hotKey, keyCodes) {
              hotKeyService.registerExitApp(hotKey)
                  .then((v) async {
                //设置为新值
                await configDao.addOrUpdate(ConfigKey.exitAppHotKeys, keyCodes);
                ref.invalidate(hotkeySettingsProvider);
                //更新托盘菜单
                final tray = ref.read(trayProvider.notifier);
                await tray.updateTrayMenus(false);
              })
                  .catchError((err) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(
                  context,
                  text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err}),
                );
              });
            },
            onClear: () {
              dialogManager.tips(
                context,
                text: TranslationKey.clearHotKeyConfirm.tr,
                actions: DialogActions(
                  cancel: const DialogAction(),
                  confirm: DialogAction(
                    onPressed: () async {
                      await configDao.addOrUpdate(ConfigKey.exitAppHotKeys, '');
                      ref.invalidate(hotkeySettingsProvider);
                      hotKeyService.unRegister(HotKeyType.exitApp);
                      final tray = ref.read(trayProvider.notifier);
                      await tray.updateTrayMenus(false);
                    },
                  ),
                ),
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                dialogManager.open(context, dialog);
              },
              child: Text(desc),
            ),
          );
        },
        show: (v) => isDesktop,
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    return [
      ...buildWinVTakeOverEntries(context, ref),
      ...buildHotKeyEntries(context, ref),
    ];
  }

  /// 开启 Win+V 接管后立即写入注册表，并注册固定的历史弹窗快捷键。
  Future<void> _enableWinVTakeover(BuildContext context, WidgetRef ref) async {
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final dialog = dialogManager.loading(context, loadingText: TranslationKey.applyingSettings.tr);
    try {
      final changed = await takeOverWinV();
      if (changed) {
        await restartExplorer();
      }
      final hotKeyService = ref.read(hotKeyProvider.notifier);
      final hotKey = toSystemHotKey(winVHistoryWindowKeys);
      await hotKeyService.registerHistoryWindow(hotKey);
      await configDao.addOrUpdate(ConfigKey.takeOverWinV, true.toString());
      ref.invalidate(hotkeySettingsProvider);
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(
        context,
        title: TranslationKey.errorDialogTitle.tr,
        text: err.toString(),
      );
    } finally {
      dialog.close();
    }
  }

  /// 关闭 Win+V 接管后恢复注册表，并回到用户原本保存的历史弹窗快捷键。
  Future<void> _disableWinVTakeover(BuildContext context, WidgetRef ref) async {
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final dialog = dialogManager.loading(context, loadingText: TranslationKey.applyingSettings.tr);
    try {
      final changed = await restoreWinV();
      if (changed) {
        await restartExplorer();
      }
      final historyWindowHotKeys = ref.read(hotkeySettingsProvider).requireValue.historyWindowHotKeys;
      final hotKeyService = ref.read(hotKeyProvider.notifier);
      if (historyWindowHotKeys.isNotEmpty) {
        final hotKey = toSystemHotKey(historyWindowHotKeys);
        await hotKeyService.registerHistoryWindow(hotKey);
      } else {
        await hotKeyService.unRegister(HotKeyType.historyWindow);
      }
      await configDao.addOrUpdate(ConfigKey.takeOverWinV, false.toString());
      ref.invalidate(hotkeySettingsProvider);
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(
        context,
        title: TranslationKey.errorDialogTitle.tr,
        text: err.toString(),
      );
    } finally {
      dialog.close();
    }
  }
}
