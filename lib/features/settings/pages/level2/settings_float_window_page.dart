import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/settings/float/float_window_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsFloatWindowPage extends SettingsSectionView {
  const SettingsFloatWindowPage({super.key, super.embedded}) : super(section: SettingsSection.floatWindow);

  static const tag = 'SettingsFloatWindowPage';
  static const _colorSyncDebounce = Duration(milliseconds: 32);
  static const _defaultHandleColor = Color(defaultHistoryFloatHandleColor);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: SettingsSection.floatWindow.title,
        icon: Icon(SettingsSection.floatWindow.icon),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final androidChannel = ref.read(androidChannelProvider.notifier);
    final floatWindowSettings = ref.watch(floatWindowSettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsEnhanceBackgroundKeepAliveTitle,
          TranslationKey.commonSettingsEnhanceBackgroundKeepAliveDesc,
        ],
        title: Text(TranslationKey.commonSettingsEnhanceBackgroundKeepAliveTitle.tr),
        description: Text(TranslationKey.commonSettingsEnhanceBackgroundKeepAliveDesc.tr),
        value: floatWindowSettings.enhanceBackgroundKeepAlive,
        action: (v) => Switch(
          value: floatWindowSettings.enhanceBackgroundKeepAlive,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            if (checked) {
              final hasPermission = await androidChannel.checkAlertWindowPermission();
              if (!hasPermission) {
                await androidChannel.grantAlertWindowPermission();
                return;
              }
              await androidChannel.showKeepAliveFloatWindow();
            } else {
              await androidChannel.closeKeepAliveFloatWindow();
            }
            await configDao.addOrUpdate(ConfigKey.enhanceBackgroundKeepAlive, checked.toString());
            ref.invalidate(floatWindowSettingsProvider);
          },
        ),
        show: (v) => isAndroid,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsShowHistoriesFloatWindow,
          TranslationKey.commonSettingsShowHistoriesFloatWindowTips,
          TranslationKey.commonSettingsHistoriesFloatWindowHandleWidthValue,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.commonSettingsShowHistoriesFloatWindow.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                dialogManager.tips(
                  context,
                  text: TranslationKey.commonSettingsShowHistoriesFloatWindowTips.tr,
                );
              },
              child: const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 15,
              ),
            ),
          ],
        ),
        description: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 30,
                child: Slider(
                  min: 5,
                  max: 50,
                  divisions: 26,
                  padding: EdgeInsets.zero,
                  value: floatWindowSettings.historyFloatHandleWidth.toDouble(),
                  label: TranslationKey.commonSettingsHistoriesFloatWindowHandleWidthValue.trParams({
                    'width': floatWindowSettings.historyFloatHandleWidth.toString(),
                  }),
                  onChanged: floatWindowSettings.showHistoryFloat
                      ? (value) async {
                          await HapticFeedback.mediumImpact();
                          final width = value.round();
                          await androidChannel.setHistoryFloatHandleWidth(width);
                          await configDao.addOrUpdate(ConfigKey.historyFloatHandleWidth, width.toString());
                          ref.invalidate(floatWindowSettingsProvider);
                        }
                      : null,
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                floatWindowSettings.historyFloatHandleWidth.toString(),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        value: floatWindowSettings.showHistoryFloat,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            if (checked) {
              await androidChannel.showHistoryFloatWindow();
            } else {
              await androidChannel.closeHistoryFloatWindow();
            }
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.showHistoryFloat, checked.toString());
            ref.invalidate(floatWindowSettingsProvider);
          },
        ),
        show: (v) => isAndroid,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsHistoriesFloatWindowHandleColor,
          TranslationKey.commonSettingsHistoriesFloatWindowHandleColorTips,
        ],
        title: Text(TranslationKey.commonSettingsHistoriesFloatWindowHandleColor.tr),
        description: Text(TranslationKey.commonSettingsHistoriesFloatWindowHandleColorTips.tr),
        value: floatWindowSettings.historyFloatHandleColor,
        onTap: () => _showHandleColorDialog(context, ref),
        action: (v) => Row(
          children: [
            _HandleColorPreview(color: Color(v)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
          ],
        ),
        show: (v) => isAndroid && floatWindowSettings.showHistoryFloat,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle,
          TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips,
        ],
        title: Text(
          TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle.tr,
        ),
        description: Text(
          TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips.tr,
        ),
        value: floatWindowSettings.historyFloatHandleApplyAlphaToWholeHandle,
        action: (v) => Switch(
          value: floatWindowSettings.historyFloatHandleApplyAlphaToWholeHandle,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.historyFloatHandleApplyAlphaToWholeHandle, checked.toString());
            await androidChannel.setHistoryFloatHandleApplyAlphaToWholeHandle(
              checked,
            );
            ref.invalidate(floatWindowSettingsProvider);
          },
        ),
        show: (v) => isAndroid && floatWindowSettings.showHistoryFloat,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsLockHistoriesFloatWindowPosition,
        ],
        title: Text(
          TranslationKey.commonSettingsLockHistoriesFloatWindowPosition.tr,
        ),
        value: floatWindowSettings.lockHistoryFloatLoc,
        action: (v) => Switch(
          value: floatWindowSettings.lockHistoryFloatLoc,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await androidChannel.lockHistoryFloatLoc(checked);
            await configDao.addOrUpdate(ConfigKey.lockHistoryFloatLoc, checked.toString());
            ref.invalidate(floatWindowSettingsProvider);
          },
        ),
        show: (v) => isAndroid && floatWindowSettings.showHistoryFloat,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.enablePIP,
          TranslationKey.enablePIPTip,
        ],
        title: Text(TranslationKey.enablePIP.tr, maxLines: 1),
        description: Text(TranslationKey.enablePIPTip.tr, maxLines: 1),
        value: floatWindowSettings.enablePIP,
        padding: const EdgeInsets.all(16),
        action: (v) {
          return Switch(
            value: floatWindowSettings.enablePIP,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(ConfigKey.enablePIP, checked.toString());
              if (checked) {
                final tempPath = await FileUtil.copyAssetToTemp(iosPIPDefaultVideoPath);
                final result = await clipboardManager.startPIP(tempPath);
                logger.debug(tag, 'start pip $result');
              } else {
                final result = await clipboardManager.stopPIP();
                logger.debug(tag, 'stop pip $result');
              }
              ref.invalidate(floatWindowSettingsProvider);
            },
          );
        },
        show: (v) => isIOS,
      ),
    ];
  }

  void _showHandleColorDialog(BuildContext context, WidgetRef ref) {
    final floatWindowSettings = ref.watch(floatWindowSettingsProvider).requireValue;
    final initialColor = Color(floatWindowSettings.historyFloatHandleColor);
    var pickerColor = initialColor;
    var finalColorValue = initialColor.toARGB32();
    DialogController? dialogController;
    Timer? syncTimer;
    final androidChannel = ref.read(androidChannelProvider.notifier);
    final configDao = ref.read(appDbProvider).requireValue.configDao;

    void syncNativeColor(Color color) {
      syncTimer?.cancel();
      syncTimer = Timer(_colorSyncDebounce, () {
        // Sync the Android overlay while the user drags the RGBA picker.
        androidChannel.setHistoryFloatHandleColor(color.toARGB32());
      });
    }

    void applyFinalColor() {
      syncTimer?.cancel();
      // Always restore the persisted value after the dialog disappears.
      androidChannel.setHistoryFloatHandleColor(finalColorValue);
    }

    dialogController = dialogManager.open(
      context,
      SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(TranslationKey.commonSettingsHistoriesFloatWindowHandleColor.tr),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  enableAlpha: true,
                  labelTypes: const [],
                  portraitOnly: true,
                  hexInputBar: true,
                  onColorChanged: (color) {
                    // Avoid rebuilding the picker on every drag, otherwise pure
                    // white loses its HSV hue and the hue slider appears stuck.
                    pickerColor = color;
                    syncNativeColor(color);
                  },
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actions: [
                SizedBox(
                  width: double.maxFinite,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Restore the shared default preview without persisting until confirm.
                            pickerColor = _defaultHandleColor;
                          });
                          syncNativeColor(_defaultHandleColor);
                        },
                        child: Text(TranslationKey.dialogRestoreDefaultText.tr),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          dialogController?.close();
                        },
                        child: Text(TranslationKey.dialogCancelText.tr),
                      ),
                      TextButton(
                        onPressed: () async {
                          finalColorValue = pickerColor.toARGB32();
                          await configDao.addOrUpdate(ConfigKey.historyFloatHandleColor, finalColorValue.toString());
                          await dialogController?.close();
                        },
                        child: Text(TranslationKey.dialogConfirmText.tr),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    dialogController.future.whenComplete(applyFinalColor);
  }
}

class _HandleColorPreview extends StatelessWidget {
  final Color color;

  const _HandleColorPreview({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x29000000),
        ),
      ),
    );
  }
}
