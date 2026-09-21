import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/src/core.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPreferencePage extends SettingsSectionView {
  const SettingsPreferencePage({
    super.key,
    super.embedded,
  }) : super(section: SettingsSection.preference);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: false,
        cardList: buildCommonEntries(context, ref),
      ),
      const SizedBox(height: 12),
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.preference.tr,
        icon: const Icon(Icons.tune),
        cardList: buildPopupEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    return [
      ...buildCommonEntries(context, ref),
      ...buildPopupEntries(context, ref),
    ];
  }

  List<SettingEntry> buildCommonEntries(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(preferenceSettingsProvider).requireValue;
    final notification = ref.watch(notificationSettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
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
          "${preference.rememberWindowSize ? "${TranslationKey.preferenceSettingsWindowSizeRecordValue.tr}: ${preference.windowSize.str}，" : ""}${TranslationKey.preferenceSettingsWindowSizeDefaultValue.tr}: ${defaultWindowSize.str}",
        ),
        value: preference.rememberWindowSize,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.rememberWindowSize, checked.toString());
            final size = await windowManager.getSize();
            await configDao.addOrUpdate(ConfigKey.windowSize, size.str);
            ref.invalidate(preferenceSettingsProvider);
            //todo linux是否有效？
          },
        ),
        show: (v) => isWindows || isMacOS,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.showOnRecentTasks,
          TranslationKey.showOnRecentTasksDesc,
        ],
        title: Text(TranslationKey.showOnRecentTasks.tr),
        description: Text(TranslationKey.showOnRecentTasksDesc.tr),
        value: preference.showOnRecentTasks,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              final androidChannel = ref.read(androidChannelProvider.notifier);
              androidChannel.showOnRecentTasks(checked).then((v) async {
                if (v) {
                  await configDao.addOrUpdate(ConfigKey.showOnRecentTasks, checked.toString());
                  ref.invalidate(preferenceSettingsProvider);
                }
              });
            },
          );
        },
        show: (v) => isAndroid,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.showMoreItemsInRow,
          TranslationKey.showMoreItemsInRowDesc,
        ],
        title: Text(TranslationKey.showMoreItemsInRow.tr),
        description: Text(TranslationKey.showMoreItemsInRowDesc.tr),
        value: preference.showMoreItemsInRow,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(ConfigKey.showMoreItemsInRow, checked.toString());
              ref.invalidate(preferenceSettingsProvider);
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
        value: preference.useTrayFlashingForConnection,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(ConfigKey.useTrayFlashingForConnection, checked.toString());
              ref.invalidate(preferenceSettingsProvider);
            },
          );
        },
        show: (v) => isDesktop && (notification.notifyOnDevConn || notification.notifyOnDevDisconn),
      ),
    ];
  }

  List<SettingEntry> buildPopupEntries(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(preferenceSettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
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
        description: Text("${TranslationKey.current.tr}: ${preference.recordHistoryDialogPosition ? TranslationKey.rememberLastPos.tr : TranslationKey.followMousePos.tr}"),
        value: preference.recordHistoryDialogPosition,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.recordHistoryDialogPosition, checked.toString());
            if (checked) {
              await configDao.addOrUpdate(ConfigKey.historyDialogPosition, '');
            }
            ref.invalidate(preferenceSettingsProvider);
          },
        ),
        show: (v) => isDesktop,
      ),
      //弹窗记住上次尺寸
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsRecordsDialogSize,
        ],
        title: Text(
          TranslationKey.preferenceSettingsRecordsDialogSize.tr,
        ),
        value: preference.rememberPopupWindowSize,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.rememberPopupWindowSize, checked.toString());
            ref.invalidate(preferenceSettingsProvider);
          },
        ),
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.preferenceSettingsAutoClosePopupOnBlurTitle,
          TranslationKey.preferenceSettingsAutoClosePopupOnBlurDesc,
        ],
        title: Text(TranslationKey.preferenceSettingsAutoClosePopupOnBlurTitle.tr),
        description: Text(TranslationKey.preferenceSettingsAutoClosePopupOnBlurDesc.tr),
        value: preference.autoClosePopupOnBlur,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(ConfigKey.autoClosePopupOnBlur, checked.toString());
            ref.invalidate(preferenceSettingsProvider);
          },
        ),
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.closeOnSameHotKeyTitle,
          TranslationKey.closeOnSameHotKeyDesc,
        ],
        title: Text(TranslationKey.closeOnSameHotKeyTitle.tr),
        description: Text(TranslationKey.closeOnSameHotKeyDesc.tr),
        value: preference.closeOnSameHotKey,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(ConfigKey.closeOnSameHotKey, checked.toString());
              ref.invalidate(preferenceSettingsProvider);
            },
          );
        },
        show: (v) => isDesktop,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.clickToPasteTitle,
          TranslationKey.clickToPasteDescSingle,
          TranslationKey.clickToPasteDescDouble,
        ],
        title: Text(TranslationKey.clickToPasteTitle.tr),
        description: Text(preference.clickToPaste ? TranslationKey.clickToPasteDescSingle.tr : TranslationKey.clickToPasteDescDouble.tr),
        value: preference.clickToPaste,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(ConfigKey.clickToPaste, checked.toString());
              ref.invalidate(preferenceSettingsProvider);
            },
          );
        },
        show: (v) => isDesktop,
      ),
    ];
  }
}
