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
                    await HapticFeedback.mediumImpact();
                    await configDao.addOrUpdate(ConfigKey.restoreWinVOnExit, checked.toString());
                    final _ = await ref.refresh(hotkeySettingsProvider.future);
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
    final registeredHotKeys = ref.watch(hotKeyProvider).value ?? const {};
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
          final desc = registeredHotKeys[HotKeyType.historyWindow]?.desc;
          DialogController? editorController;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.historyWindow,
            initContent: desc ?? '',
            clearable: true,
            onDone: (hotKey, keyCodes) {
              _saveHotKey(
                context,
                ref,
                register: () => hotKeyService.registerHistoryWindow(hotKey),
                configKey: ConfigKey.historyWindowHotKeys,
                keyCodes: keyCodes,
                updateTray: false,
              );
            },
            onClear: () {
              _clearHotKey(
                context,
                ref,
                type: HotKeyType.historyWindow,
                configKey: ConfigKey.historyWindowHotKeys,
                editor: editorController!,
                updateTray: false,
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
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
          final desc = registeredHotKeys[HotKeyType.fileSender]?.desc;
          DialogController? editorController;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.fileSender,
            initContent: desc ?? '',
            clearable: true,
            onDone: (hotKey, keyCodes) {
              _saveHotKey(
                context,
                ref,
                register: () => hotKeyService.registerFileSync(hotKey),
                configKey: ConfigKey.syncFileHotKeys,
                keyCodes: keyCodes,
                updateTray: false,
              );
            },
            onClear: () {
              _clearHotKey(
                context,
                ref,
                type: HotKeyType.fileSender,
                configKey: ConfigKey.syncFileHotKeys,
                editor: editorController!,
                updateTray: false,
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
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
          final desc = registeredHotKeys[HotKeyType.showMainWindows]?.desc;
          DialogController? editorController;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.showMainWindows,
            initContent: desc ?? '',
            clearable: desc != null,
            onDone: (hotKey, keyCodes) {
              _saveHotKey(
                context,
                ref,
                register: () => hotKeyService.registerShowMainWindow(hotKey),
                configKey: ConfigKey.showMainWindowHotKeys,
                keyCodes: keyCodes,
                updateTray: true,
              );
            },
            onClear: () {
              _clearHotKey(
                context,
                ref,
                type: HotKeyType.showMainWindows,
                configKey: ConfigKey.showMainWindowHotKeys,
                editor: editorController!,
                updateTray: true,
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
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
          final desc = registeredHotKeys[HotKeyType.exitApp]?.desc;
          DialogController? editorController;
          final dialog = HotKeyEditorDialog(
            hotKeyType: HotKeyType.exitApp,
            initContent: desc ?? '',
            clearable: desc != null,
            onDone: (hotKey, keyCodes) {
              _saveHotKey(
                context,
                ref,
                register: () => hotKeyService.registerExitApp(hotKey),
                configKey: ConfigKey.exitAppHotKeys,
                keyCodes: keyCodes,
                updateTray: true,
              );
            },
            onClear: () {
              _clearHotKey(
                context,
                ref,
                type: HotKeyType.exitApp,
                configKey: ConfigKey.exitAppHotKeys,
                editor: editorController!,
                updateTray: true,
              );
            },
          );
          if (desc == null) {
            return TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
              },
              child: Text(TranslationKey.create.tr),
            );
          }
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: TextButton(
              onPressed: () {
                editorController = dialogManager.open(context, dialog);
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

  /// 执行 [register] 后持久化 [configKey]；[updateTray] 指定是否同步托盘标签。
  Future<void> _saveHotKey(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() register,
    required ConfigKey configKey,
    required String keyCodes,
    required bool updateTray,
  }) async {
    // 保存容器而非在异步完成后访问 WidgetRef，页面关闭不应中断配置同步。
    final container = ProviderScope.containerOf(context, listen: false);
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    try {
      await register();
      await configDao.addOrUpdate(configKey, keyCodes);
      final _ = await container.refresh(hotkeySettingsProvider.future);
      if (updateTray) {
        final tray = container.read(trayProvider.notifier);
        await tray.updateTrayMenus(false);
      }
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      if (!context.mounted) {
        return;
      }
      await dialogManager.tips(
        context,
        text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err.toString()}),
      );
    }
  }

  /// 确认后注销 [type] 并清空 [configKey]，持久化成功才关闭指定 [editor]。
  /// [updateTray] 为 true 时等待新配置加载后同步托盘标签。
  Future<void> _clearHotKey(
    BuildContext context,
    WidgetRef ref, {
    required HotKeyType type,
    required ConfigKey configKey,
    required DialogController editor,
    required bool updateTray,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final hotKeyService = ref.read(hotKeyProvider.notifier);
    await dialogManager.tips(
      context,
      text: TranslationKey.clearHotKeyConfirm.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () async {
            try {
              await hotKeyService.unRegister(type);
              await configDao.addOrUpdate(configKey, '');
              final _ = await container.refresh(hotkeySettingsProvider.future);
              await editor.close();
              if (updateTray) {
                final tray = container.read(trayProvider.notifier);
                await tray.updateTrayMenus(false);
              }
            } catch (err, stack) {
              logger.error(_tag, err, stack);
              if (!context.mounted) {
                return;
              }
              await dialogManager.tips(
                context,
                text: TranslationKey.hotKeySettingsSaveKeysFailedText.trParams({'err': err.toString()}),
              );
            }
          },
        ),
      ),
    );
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
      final _ = await ref.refresh(hotkeySettingsProvider.future);
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
      final _ = await ref.refresh(hotkeySettingsProvider.future);
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
