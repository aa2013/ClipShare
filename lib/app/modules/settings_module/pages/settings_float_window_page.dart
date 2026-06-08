import 'settings_section_view_base.dart';

class SettingsFloatWindowPage extends SettingsSectionView {
  SettingsFloatWindowPage({super.key, super.embedded}) : super(section: SettingsSection.floatWindow);

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
          TranslationKey.commonSettingsShowHistoriesFloatWindow,
          TranslationKey.commonSettingsHistoriesFloatWindowHandleWidthValue,
        ],
        title: Text(TranslationKey.commonSettingsShowHistoriesFloatWindow.tr),
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
                Log.debug(logTag, "start pip $result");
              } else {
                final result = await clipboardManager.stopPIP();
                Log.debug(logTag, "stop pip $result");
              }
            },
          );
        },
        show: (v) => Platform.isIOS,
      ),
    ];
  }
}
