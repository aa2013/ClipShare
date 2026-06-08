import 'settings_section_view_base.dart';

class SettingsNotificationPage extends SettingsSectionView {
  SettingsNotificationPage({super.key, super.embedded}) : super(section: SettingsSection.notification);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.notification.tr,
          icon: const Icon(Icons.notifications_active_outlined),
          cardList: buildSettingEntries(context),
        ),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [TranslationKey.recordNotification],
        title: Text(TranslationKey.recordNotification.tr),
        value: appConfig.enableRecordNotification,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            HapticFeedback.mediumImpact();
            final androidNotificationListenerService = Get.find<AndroidNotificationListenerService>();
            if (checked) {
              var isGranted = await NotificationListenerService.isPermissionGranted();
              if (!isGranted) {
                try {
                  await NotificationListenerService.requestPermission();
                } catch (_) {
                  // ignored
                }
                isGranted = await NotificationListenerService.isPermissionGranted();
                if (isGranted) {
                  appConfig.setEnableRecordNotification(checked);
                  androidNotificationListenerService.startListening();
                }
                return;
              } else {
                androidNotificationListenerService.startListening();
              }
            } else {
              androidNotificationListenerService.stopListening();
            }
            appConfig.setEnableRecordNotification(checked);
          },
        ),
        show: (v) => Platform.isAndroid,
      ),
      SettingCard(
        searchKeys: const [TranslationKey.preferenceSettingsDevConnNotification],
        title: Text(
          TranslationKey.preferenceSettingsDevConnNotification.tr,
        ),
        value: appConfig.notifyOnDevConn,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) {
            HapticFeedback.mediumImpact();
            appConfig.setNotifyOnDevConn(checked);
          },
        ),
      ),
      SettingCard(
        searchKeys: const [TranslationKey.preferenceSettingsDevDisconnNotification],
        title: Text(
          TranslationKey.preferenceSettingsDevDisconnNotification.tr,
        ),
        value: appConfig.notifyOnDevDisconn,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) {
            HapticFeedback.mediumImpact();
            appConfig.setNotifyOnDevDisconn(checked);
          },
        ),
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsShowMobileNotificationTitle,
          TranslationKey.preferenceSettingsShowMobileNotificationDesc,
        ],
        title: Text(TranslationKey.preferenceSettingsShowMobileNotificationTitle.tr),
        description: Text(TranslationKey.preferenceSettingsShowMobileNotificationDesc.tr),
        value: appConfig.enableShowMobileNotification,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) {
            HapticFeedback.mediumImpact();
            appConfig.setEnableShowMobileNotification(checked);
          },
        ),
        show: (v) => PlatformExt.isDesktop,
      ),
    ];
  }
}
