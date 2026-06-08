import 'settings_section_view_base.dart';

class SettingsPreferencePage extends SettingsSectionView {
  SettingsPreferencePage({super.key, super.embedded}) : super(section: SettingsSection.preference);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.preference.tr,
          icon: const Icon(Icons.tune),
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
}
