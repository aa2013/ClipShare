import 'settings_section_view_base.dart';

class SettingsPermissionPage extends SettingsSectionView {
  SettingsPermissionPage({super.key, super.embedded}) : super(section: SettingsSection.permission);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.permissionSettingsGroupName.tr,
          icon: const Icon(Icons.admin_panel_settings),
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
          TranslationKey.permissionSettingsNotificationTitle,
          TranslationKey.permissionSettingsNotificationDesc,
        ],
        title: Text(TranslationKey.permissionSettingsNotificationTitle.tr),
        description: Platform.isAndroid ? Text(TranslationKey.permissionSettingsNotificationDesc.tr) : null,
        value: controller.hasNotifyPerm.value,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => (Platform.isAndroid || Platform.isIOS) && !v,
        onTap: () {
          if (!controller.hasNotifyPerm.value) {
            if (Platform.isIOS) {
              openAppSettings();
            } else {
              controller.notifyHandler.request();
            }
          }
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsFloatTitle,
          TranslationKey.permissionSettingsFloatDesc,
        ],
        title: Text(TranslationKey.permissionSettingsFloatTitle.tr),
        description: Text(TranslationKey.permissionSettingsFloatDesc.tr),
        value: controller.hasFloatPerm.value,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () {
          if (!controller.hasFloatPerm.value) {
            controller.floatHandler.request();
          }
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsBatteryOptimiseTitle,
          TranslationKey.permissionSettingsBatteryOptimiseDesc,
        ],
        title: Text(TranslationKey.permissionSettingsBatteryOptimiseTitle.tr),
        description: Text(TranslationKey.permissionSettingsBatteryOptimiseDesc.tr),
        value: controller.hasIgnoreBattery.value,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () {
          if (!controller.hasIgnoreBattery.value) {
            controller.ignoreBatteryHandler.request();
          }
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsSmsTitle,
          TranslationKey.permissionSettingsSmsDesc,
        ],
        title: Text(TranslationKey.permissionSettingsSmsTitle.tr),
        description: Text(TranslationKey.permissionSettingsSmsDesc.tr),
        value: controller.hasSmsReadPerm.value,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsAccessibilityTitle,
          TranslationKey.permissionSettingsAccessibilityDesc,
        ],
        title: Text(TranslationKey.permissionSettingsAccessibilityTitle.tr),
        description: Text(TranslationKey.permissionSettingsAccessibilityDesc.tr),
        value: !controller.hasAccessibilityPerm.value && appConfig.sourceRecord && !appConfig.ignoreAccessibility,
        action: (val) => const Icon(
          Icons.help,
          color: Colors.orange,
        ),
        show: (v) => Platform.isAndroid && v,
        onTap: () {
          PermissionHelper.reqAndroidAccessibilityPerm();
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsNotificationRecordTitle,
          TranslationKey.permissionSettingsNotificationRecordDesc,
        ],
        title: Text(TranslationKey.permissionSettingsNotificationRecordTitle.tr),
        description: Text(TranslationKey.permissionSettingsNotificationRecordDesc.tr),
        value: (!controller.hasNotificationRecordPerm.value && appConfig.enableRecordNotification) || (controller.hasNotificationRecordPerm.value && !appConfig.enableRecordNotification),
        action: (val) => const Icon(
          Icons.help,
          color: Colors.orange,
        ),
        show: (v) => Platform.isAndroid && v,
        onTap: () {
          NotificationListenerService.requestPermission();
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsIOSPhotosTitle,
          TranslationKey.permissionSettingsIOSPhotosDesc,
        ],
        title: Text(TranslationKey.permissionSettingsIOSPhotosTitle.tr),
        description: Text(TranslationKey.permissionSettingsIOSPhotosDesc.tr),
        value: controller.hasIOSPhotosPerm.value,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isIOS && !v,
        onTap: () {
          if (!controller.hasIOSPhotosPerm.value) {
            controller.iosPhotosHandler.request();
          }
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsClipboardTitle,
          TranslationKey.permissionSettingsClipboardDesc,
        ],
        title: Text(TranslationKey.permissionSettingsClipboardTitle.tr),
        description: Text(TranslationKey.permissionSettingsClipboardDesc.tr),
        value: controller.hasClipboardPerm.value,
        action: (val) => const Icon(
          Icons.help,
          color: Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () async {
          final isValidWorkingMode = appConfig.workingMode == EnvironmentType.shizuku || appConfig.workingMode == EnvironmentType.root;
          if (!isValidWorkingMode) {
            Global.showTipsDialog(context: context, text: TranslationKey.clipboardPermissionRequestFailed.tr);
            return;
          } else {
            try {
              await clipboardManager.requestClipboardPermission();
              controller.hasClipboardPerm.value = await clipboardManager.checkClipboardPermission();
              final tips = controller.hasClipboardPerm.value ? TranslationKey.requestSuccess.tr : TranslationKey.requestFailed.tr;
              Global.showSnackBarSuc(context: context, text: tips);
            } catch (err, stack) {
              Global.showTipsDialog(context: context, text: "$err,$stack", title: TranslationKey.requestFailed.tr);
            }
          }
        },
      ),
    ];
  }
}
