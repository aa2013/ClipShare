import 'dart:async';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'settings_section_view_base.dart';

class SettingsFloatWindowPage extends SettingsSectionView {
  SettingsFloatWindowPage({super.key, super.embedded}) : super(section: SettingsSection.floatWindow);

  static const _colorSyncDebounce = Duration(milliseconds: 32);
  static const _defaultHandleColor = Color(Constants.defaultHistoryFloatHandleColor);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: SettingsSection.floatWindow.title,
          icon: Icon(SettingsSection.floatWindow.icon),
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
          TranslationKey.commonSettingsEnhanceBackgroundKeepAliveTitle,
          TranslationKey.commonSettingsEnhanceBackgroundKeepAliveDesc,
        ],
        title: Text(TranslationKey.commonSettingsEnhanceBackgroundKeepAliveTitle.tr),
        description: Text(TranslationKey.commonSettingsEnhanceBackgroundKeepAliveDesc.tr),
        value: appConfig.enhanceBackgroundKeepAlive,
        action: (v) => Switch(
          value: appConfig.enhanceBackgroundKeepAlive,
          onChanged: (checked) async {
            HapticFeedback.mediumImpact();
            if (checked) {
              final hasPermission = await androidChannelService.checkAlertWindowPermission();
              controller.hasFloatPerm.value = hasPermission;
              if (!hasPermission) {
                await androidChannelService.grantAlertWindowPermission();
                return;
              }
              androidChannelService.showKeepAliveFloatWindow();
            } else {
              androidChannelService.closeKeepAliveFloatWindow();
            }
            appConfig.setEnhanceBackgroundKeepAlive(checked);
          },
        ),
        show: (v) => Platform.isAndroid,
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
                // Reuse the standard tips dialog so this setting matches other annotated settings.
                Global.showTipsDialog(
                  context: context,
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
                  min: 24,
                  max: 50,
                  divisions: 26,
                  padding: EdgeInsets.zero,
                  value: appConfig.historyFloatHandleWidth.toDouble(),
                  label: TranslationKey.commonSettingsHistoriesFloatWindowHandleWidthValue.trParams({
                    "width": appConfig.historyFloatHandleWidth.toString(),
                  }),
                  onChanged: appConfig.showHistoryFloat
                      ? (value) {
                          HapticFeedback.mediumImpact();
                          final width = value.round();
                          androidChannelService.setHistoryFloatHandleWidth(width);
                          appConfig.setHistoryFloatHandleWidth(width);
                        }
                      : null,
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                appConfig.historyFloatHandleWidth.toString(),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
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
        searchKeys: const [
          TranslationKey.commonSettingsHistoriesFloatWindowHandleColor,
          TranslationKey.commonSettingsHistoriesFloatWindowHandleColorTips,
        ],
        title: Text(TranslationKey.commonSettingsHistoriesFloatWindowHandleColor.tr),
        description: Text(TranslationKey.commonSettingsHistoriesFloatWindowHandleColorTips.tr),
        value: appConfig.historyFloatHandleColor,
        onTap: () => _showHandleColorDialog(context),
        action: (_) => Row(
          children: [
            _HandleColorPreview(color: Color(appConfig.historyFloatHandleColor)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
          ],
        ),
        show: (v) => Platform.isAndroid && appConfig.showHistoryFloat,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.commonSettingsLockHistoriesFloatWindowPosition,
        ],
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
      SettingCard(
        searchKeys: const [
          TranslationKey.enablePIP,
          TranslationKey.enablePIPTip,
        ],
        title: Text(TranslationKey.enablePIP.tr, maxLines: 1),
        description: Text(TranslationKey.enablePIPTip.tr, maxLines: 1),
        value: appConfig.enablePIP,
        padding: const EdgeInsets.all(16),
        action: (v) {
          return Switch(
            value: appConfig.enablePIP,
            onChanged: (checked) async {
              HapticFeedback.mediumImpact();
              appConfig.setEnablePIP(checked);
              if (checked) {
                final tempPath = await FileUtil.copyAssetToTemp(Constants.iosPIPDefaultVideoPath);
                final result = await clipboardManager.startPIP(tempPath);
                logger.debug(logTag, "start pip $result");
              } else {
                final result = await clipboardManager.stopPIP();
                logger.debug(logTag, "stop pip $result");
              }
            },
          );
        },
        show: (v) => Platform.isIOS,
      ),
    ];
  }

  void _showHandleColorDialog(BuildContext context) {
    final initialColor = Color(appConfig.historyFloatHandleColor);
    var pickerColor = initialColor;
    var finalColorValue = initialColor.toARGB32();
    DialogController? dialogController;
    Timer? syncTimer;

    void syncNativeColor(Color color) {
      syncTimer?.cancel();
      syncTimer = Timer(_colorSyncDebounce, () {
        // Sync the Android overlay while the user drags the RGBA picker.
        androidChannelService.setHistoryFloatHandleColor(color.toARGB32());
      });
    }

    void applyFinalColor() {
      syncTimer?.cancel();
      // Always restore the persisted value after the dialog disappears.
      androidChannelService.setHistoryFloatHandleColor(finalColorValue);
    }

    dialogController = Global.showDialog(
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
                          await appConfig.setHistoryFloatHandleColor(finalColorValue);
                          dialogController?.close();
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
