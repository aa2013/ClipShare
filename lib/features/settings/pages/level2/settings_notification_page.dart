import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/android/android_notification_listener_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class SettingsNotificationPage extends SettingsSectionView {
  const SettingsNotificationPage({super.key, super.embedded}) : super(section: SettingsSection.notification);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.notification.tr,
        icon: const Icon(Icons.notifications_active_outlined),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    return [
      SettingCard(
        searchKeys: const [TranslationKey.recordNotification],
        title: Text(TranslationKey.recordNotification.tr),
        value: notificationSettings.enableRecordNotification,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            final androidNotificationListener = ref.read(androidNotificationListenerProvider.notifier);
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
                  await configDao.addOrUpdate(.enableRecordNotification, checked.toString());
                  ref.invalidate(notificationSettingsProvider);
                  androidNotificationListener.startListening();
                }
                return;
              } else {
                androidNotificationListener.startListening();
              }
            } else {
              androidNotificationListener.stopListening();
            }
            await configDao.addOrUpdate(.enableRecordNotification, checked.toString());
            ref.invalidate(notificationSettingsProvider);
          },
        ),
        show: (v) => isAndroid,
      ),
      SettingCard(
        searchKeys: const [TranslationKey.preferenceSettingsDevConnNotification],
        title: Text(
          TranslationKey.preferenceSettingsDevConnNotification.tr,
        ),
        value: notificationSettings.notifyOnDevConn,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.notifyOnDevConn, checked.toString());
            ref.invalidate(notificationSettingsProvider);
          },
        ),
      ),
      SettingCard(
        searchKeys: const [TranslationKey.preferenceSettingsDevDisconnNotification],
        title: Text(
          TranslationKey.preferenceSettingsDevDisconnNotification.tr,
        ),
        value: notificationSettings.notifyOnDevDisconn,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.notifyOnDevDisconn, checked.toString());
            ref.invalidate(notificationSettingsProvider);
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
        value: notificationSettings.enableShowMobileNotification,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.enableShowMobileNotification, checked.toString());
            ref.invalidate(notificationSettingsProvider);
          },
        ),
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsNotifyOnReceivedFile,
          TranslationKey.preferenceSettingsNotifyOnReceivedFileDesc,
        ],
        title: Text(TranslationKey.preferenceSettingsNotifyOnReceivedFile.tr),
        description: Text(TranslationKey.preferenceSettingsNotifyOnReceivedFileDesc.tr),
        value: notificationSettings.notifyOnReceivedFile,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.notifyOnReceivedFile, checked.toString());
            ref.invalidate(notificationSettingsProvider);
          },
        ),
      ),
    ];
  }
}
