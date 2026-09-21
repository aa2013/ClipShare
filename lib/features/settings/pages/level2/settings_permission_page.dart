import 'dart:io';

import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/core/services/permission/permission_info_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../settings_section_view_base.dart';

class SettingsPermissionPage extends SettingsSectionView {
  static const tag = 'SettingsPermissionPage';
  const SettingsPermissionPage({super.key, super.embedded}) : super(section: SettingsSection.permission);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.permissionSettingsGroupName.tr,
        icon: const Icon(Icons.admin_panel_settings),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    var permissionInfo = ref.watch(permissionInfoProvider).requireValue;
    final permissionHandler = ref.watch(permissionInfoProvider.notifier);
    final enableRecordNotification = ref.watch(notificationSettingsProvider.select((state) => state.requireValue.enableRecordNotification));
    final clipboardSettings = ref.watch(clipboardSettingsProvider).requireValue;
    final workingMode = clipboardSettings.workingMode;
    final ignoreAccessibility = ref.watch(appStateProvider.select((state) => state.ignoreAccessibility));
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsNotificationTitle,
          TranslationKey.permissionSettingsNotificationDesc,
        ],
        title: Text(TranslationKey.permissionSettingsNotificationTitle.tr),
        description: Platform.isAndroid ? Text(TranslationKey.permissionSettingsNotificationDesc.tr) : null,
        value: permissionInfo.hasNotifyPermission,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => (Platform.isAndroid || Platform.isIOS) && !v,
        onTap: () {
          if (!permissionInfo.hasNotifyPermission) {
            if (Platform.isIOS) {
              openAppSettings();
            } else {
              permissionHandler.requestNotificationPermission(context);
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
        value: permissionInfo.hasFloatWindowPermission,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () {
          if (!permissionInfo.hasFloatWindowPermission) {
            permissionHandler.requestFloatWindowPermission(context);
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
        value: permissionInfo.hasIgnoreBatteryPermission,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () {
          if (!permissionInfo.hasIgnoreBatteryPermission) {
            permissionHandler.requestIgnoreBatteryPermission(context);
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
        value: permissionInfo.hasSmsReadPermission,
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
        value: !permissionInfo.hasAccessibilityPermission && clipboardSettings.sourceRecord && !ignoreAccessibility,
        action: (val) => const Icon(
          Icons.help,
          color: Colors.orange,
        ),
        show: (v) => Platform.isAndroid && v,
        onTap: () async {
          await permissionHandler.requestAccessibilityPermission(context);
          //自动写入 secure settings 后系统服务列表可能稍后才同步，等待后再复查一次
          await Future.delayed(1.s);
          ref.invalidate(permissionInfoProvider);
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.permissionSettingsNotificationRecordTitle,
          TranslationKey.permissionSettingsNotificationRecordDesc,
        ],
        title: Text(TranslationKey.permissionSettingsNotificationRecordTitle.tr),
        description: Text(TranslationKey.permissionSettingsNotificationRecordDesc.tr),
        value: (!permissionInfo.hasNotificationRecordPermission && enableRecordNotification) || (permissionInfo.hasNotificationRecordPermission && !enableRecordNotification),
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
        value: permissionInfo.hasIOSPhotosPermission,
        action: (val) => Icon(
          val ? Icons.check_circle : Icons.help,
          color: val ? Colors.green : Colors.orange,
        ),
        show: (v) => Platform.isIOS && !v,
        onTap: () {
          if (!permissionInfo.hasIOSPhotosPermission) {
            permissionHandler.requestIosPhotosPermission(context);
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
        value: permissionInfo.hasClipboardPermission,
        action: (val) => const Icon(
          Icons.help,
          color: Colors.orange,
        ),
        show: (v) => Platform.isAndroid && !v,
        onTap: () async {
          final isValidWorkingMode = workingMode == .shizuku || workingMode == .root;
          if (!isValidWorkingMode) {
            await dialogManager.tips(context, text: TranslationKey.clipboardPermissionRequestFailed.tr);
            return;
          } else {
            try {
              await permissionHandler.requestClipboardPermission(context);
              await Future.delayed(1.s);
              permissionInfo = await ref.refresh(permissionInfoProvider.future);
              final hasPermission = permissionInfo.hasClipboardPermission;
              if (context.mounted) {
                if (hasPermission) {
                  snackbar.success(context, TranslationKey.requestSuccess.tr);
                } else {
                  snackbar.warn(context, TranslationKey.requestFailed.tr);
                }
              }
            } catch (err, stack) {
              logger.error(tag, err, stack);
              if (context.mounted) {
                await dialogManager.tips(context, text: '$err,$stack', title: TranslationKey.requestFailed.tr);
              }
            }
          }
        },
      ),
    ];
  }
}
