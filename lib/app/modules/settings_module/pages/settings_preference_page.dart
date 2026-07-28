import 'dart:io';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import 'settings_section_view_base.dart';

class SettingsPreferencePage extends SettingsSectionView {
  SettingsPreferencePage({super.key, super.embedded}) : super(section: SettingsSection.preference);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: false,
          cardList: buildCommonEntries(context),
        ),
      ),
      const SizedBox(height: 12),
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.preference.tr,
          icon: const Icon(Icons.tune),
          cardList: buildPopupEntries(context),
        ),
      ),
    ];
  }

  List<SettingEntry> buildCommonEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsRememberWindowSize,
          TranslationKey.preferenceSettingsWindowSizeRecordValue,
          TranslationKey.preferenceSettingsWindowSizeDefaultValue,
        ],
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
      SettingCard(
        searchKeys: const [
          TranslationKey.showOnRecentTasks,
          TranslationKey.showOnRecentTasksDesc,
        ],
        title: Text(TranslationKey.showOnRecentTasks.tr),
        description: Text(TranslationKey.showOnRecentTasksDesc.tr),
        value: appConfig.showOnRecentTasks,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              androidChannelService.showOnRecentTasks(checked).then((v) {
                if (v) {
                  appConfig.setShowOnRecentTasks(checked);
                }
              });
            },
          );
        },
        show: (v) => Platform.isAndroid,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.showMoreItemsInRow,
          TranslationKey.showMoreItemsInRowDesc,
        ],
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
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.useTrayFlashingForConnectionTitle,
          TranslationKey.useTrayFlashingForConnectionDesc,
        ],
        title: Text(TranslationKey.useTrayFlashingForConnectionTitle.tr),
        description: Text(TranslationKey.useTrayFlashingForConnectionDesc.tr),
        value: appConfig.useTrayFlashingForConnection,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              appConfig.setUseTrayFlashingForConnection(checked);
            },
          );
        },
        show: (v) => PlatformExt.isDesktop && (appConfig.notifyOnDevConn || appConfig.notifyOnDevDisconn),
      ),
    ];
  }

  List<SettingEntry> buildPopupEntries(BuildContext context) {
    return [
      //弹窗记住上次位置
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsRecordsDialogLocation,
          TranslationKey.rememberLastPos,
          TranslationKey.followMousePos,
        ],
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
      //弹窗记住上次尺寸
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsRecordsDialogSize,
        ],
        title: Text(
          TranslationKey.preferenceSettingsRecordsDialogSize.tr,
        ),
        value: appConfig.rememberPopupWindowSize,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) {
            HapticFeedback.mediumImpact();
            appConfig.setRememberPopupWindowSize(checked);
          },
        ),
        show: (v) => PlatformExt.isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsAutoClosePopupOnBlurTitle,
          TranslationKey.preferenceSettingsAutoClosePopupOnBlurDesc,
        ],
        title: Text(TranslationKey.preferenceSettingsAutoClosePopupOnBlurTitle.tr),
        description: Text(TranslationKey.preferenceSettingsAutoClosePopupOnBlurDesc.tr),
        value: appConfig.autoClosePopupOnBlur,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) {
            HapticFeedback.mediumImpact();
            appConfig.setAutoClosePopupOnBlur(checked);
          },
        ),
        show: (v) => PlatformExt.isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.closeOnSameHotKeyTitle,
          TranslationKey.closeOnSameHotKeyDesc,
        ],
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
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      ...buildCommonEntries(context),
      ...buildPopupEntries(context),
    ];
  }
}
