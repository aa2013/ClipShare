import 'dart:io';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/platform/android/screenshot_detect_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/features/settings/widgets/dialog/outdate_time_input_dialog.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file_plus/open_file_plus.dart';

class SettingsSyncPage extends SettingsSectionView {
  const SettingsSyncPage({super.key, super.embedded}) : super(section: SettingsSection.sync);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.syncSettingsGroupName.tr,
        icon: const Icon(Icons.sync_rounded),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final syncSettings = ref.watch(syncSettingsProvider).requireValue;
    final appPaths = ref.watch(appPathsProvider).requireValue;
    final localDeviceInfo = ref.read(localDeviceInfoProvider).requireValue;
    final configDao = ref.watch(appDbProvider).requireValue.configDao;
    final rootStorePath = appPaths.rootStorePath;
    final androidOsVersion = localDeviceInfo.androidOsVersion;
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsAutoSyncMissingDataTitle,
          TranslationKey.syncSettingsAutoSyncMissingDataDesc,
        ],
        title: Text(
          TranslationKey.syncSettingsAutoSyncMissingDataTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.syncSettingsAutoSyncMissingDataDesc.tr),
        value: syncSettings.autoSyncMissingData,
        show: (v) => true,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.autoSyncMissingData, checked.toString());
              ref.invalidate(syncSettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.recopyOnScreenUnlockedTitle,
          TranslationKey.recopyOnScreenUnlockedTitleDesc,
        ],
        title: Text(
          TranslationKey.recopyOnScreenUnlockedTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.recopyOnScreenUnlockedTitleDesc.tr),
        value: syncSettings.reCopyOnScreenUnlocked,
        show: (v) => isAndroid,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.recopyOnScreenUnlocked, checked.toString());
              ref.invalidate(syncSettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsStoreImg2PicturesTitle,
          TranslationKey.syncSettingsStoreImg2PicturesDesc,
        ],
        title: Text(
          TranslationKey.syncSettingsStoreImg2PicturesTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.syncSettingsStoreImg2PicturesDesc.tr),
        value: syncSettings.saveToPictures,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              if (checked) {
                if (isAndroid) {
                  var path = '$androidPicturesPath/$appName';
                  var res = await PermissionHelper.testAndroidStoragePerm(rootStorePath, androidOsVersion, path);
                  if (res) {
                    await _setSaveToPictures(ref, configDao, true);
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  DialogController? dialog;
                  dialog = await dialogManager.tips(
                    context,
                    text: TranslationKey.syncSettingsStoreImg2PicturesNoPermText.tr,
                    actions: DialogActions(
                      cancel: const DialogAction(),
                      confirm: DialogAction(
                        text: TranslationKey.dialogAuthorizationButtonText.tr,
                        onPressed: () async {
                          await dialog!.close();
                          await PermissionHelper.reqAndroidStoragePerm(rootStorePath, androidOsVersion, path);
                          if (!await PermissionHelper.testAndroidStoragePerm(rootStorePath, androidOsVersion, path)) {
                            await _setSaveToPictures(ref, configDao, false);
                            if (!context.mounted) {
                              return;
                            }
                            await dialogManager.tips(
                              context,
                              text: TranslationKey.syncSettingsStoreImg2PicturesCancelPerm.tr,
                            );
                          } else {
                            await _setSaveToPictures(ref, configDao, true);
                          }
                        },
                      ),
                    ),
                  );
                } else {
                  if (!await PermissionHelper.checkIOSPhotoPermission() && !await PermissionHelper.reqIOSPhotoPermission()) {
                    await _setSaveToPictures(ref, configDao, false);
                    if (!context.mounted) {
                      return;
                    }
                    await dialogManager.tips(
                      context,
                      text: TranslationKey.noPhotoPermission.tr,
                      actions: const DialogActions(
                        confirm: DialogAction(
                          onPressed: openAppSettings,
                        ),
                      ),
                    );
                  } else {
                    await _setSaveToPictures(ref, configDao, true);
                  }
                }
              } else {
                await _setSaveToPictures(ref, configDao, false);
              }
            },
          );
        },
        show: (v) => isAndroid || isIOS,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsStoreImagePathTitle,
        ],
        title: Text(
          TranslationKey.syncSettingsStoreImagePathTitle.tr,
          maxLines: 1,
        ),
        description: Text(appPaths.imageStorePath),
        value: false,
        show: (v) => isAndroid && !syncSettings.saveToPictures,
        action: (v) {
          return TextButton(
            onPressed: () async {
              final result = await FileUtil.pickWritableDirectory();
              if (result.isUnwritable) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(context, text: TranslationKey.unWriteablePathTips.tr);
                return;
              }
              if (result.path != null) {
                await configDao.addOrUpdate(.imageStorePath, result.path!);
                ref.invalidate(syncSettingsProvider);
              }
            },
            child: Text(
              TranslationKey.selection.tr,
              maxLines: 1,
            ),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsStoreFilePathTitle,
        ],
        title: Text(
          TranslationKey.syncSettingsStoreFilePathTitle.tr,
          maxLines: 1,
        ),
        description: Visibility(
          visible: isDesktop,
          replacement: Text(appPaths.fileStorePath),
          child: Tooltip(
            message: TranslationKey.doubleClick2OpenPath.tr,
            child: Text(appPaths.fileStorePath),
          ),
        ),
        value: false,
        action: (v) {
          return TextButton(
            onPressed: () async {
              final result = await FileUtil.pickWritableDirectory();
              if (result.isUnwritable) {
                if (!context.mounted) {
                  return;
                }
                dialogManager.tips(context, text: TranslationKey.unWriteablePathTips.tr);
                return;
              }
              if (result.path != null) {
                await configDao.addOrUpdate(.fileStorePath, result.path!);
                ref.invalidate(syncSettingsProvider);
              }
            },
            child: Text(
              TranslationKey.selection.tr,
              maxLines: 1,
            ),
          );
        },
        onDoubleTap: () async {
          final dir = Directory(appPaths.fileStorePath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          await OpenFile.open(appPaths.fileStorePath);
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsAutoCopyImgTitle,
          TranslationKey.syncSettingsAutoCopyImgDesc,
        ],
        title: Text(
          TranslationKey.syncSettingsAutoCopyImgTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.syncSettingsAutoCopyImgDesc.tr),
        show: (v) => true,
        value: syncSettings.autoCopyImageAfterSync,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await configDao.addOrUpdate(
                .autoCopyImageAfterSync,
                checked.toString(),
              );
              ref.invalidate(syncSettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncSettingsAutoCopyScreenShotTitle,
          TranslationKey.syncSettingsAutoCopyScreenShotDesc,
        ],
        title: Text(
          TranslationKey.syncSettingsAutoCopyScreenShotTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.syncSettingsAutoCopyScreenShotDesc.tr),
        show: (v) => isAndroid,
        value: syncSettings.autoCopyImageAfterScreenShot,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await configDao.addOrUpdate(
                .autoCopyImageAfterScreenShot,
                checked.toString(),
              );
              ref.invalidate(syncSettingsProvider);
              final screenshotDetector = ref.read(screenshotDetectProvider.notifier);
              if (checked) {
                screenshotDetector.startListenScreenshot();
              } else {
                screenshotDetector.stopListenScreenshot();
              }
            },
          );
        },
      ),
      SettingCard<int>(
        searchKeys: const [
          TranslationKey.syncOutDateSettingTitle,
          TranslationKey.syncOutDateSettingDesc,
        ],
        title: Text(TranslationKey.syncOutDateSettingTitle.tr),
        description: Text(TranslationKey.syncOutDateSettingDesc.tr),
        value: syncSettings.syncOutdateLimitTime,
        action: (v) => Text(v == 0 ? TranslationKey.noLimits.tr : v.timeSpanStr),
        onTap: () {
          dialogManager.open(
            context,
            OutdateTimeInputDialog(
              initValue: syncSettings.syncOutdateLimitTime,
              onConfirm: (value) async {
                await configDao.addOrUpdate(.syncOutdateLimitTime, value.toString());
                ref.invalidate(syncSettingsProvider);
              },
            ),
          );
        },
      ),
    ];
  }

  Future<void> _setSaveToPictures(WidgetRef ref, ConfigDao configDao, bool saveToPictures) async {
    await configDao.addOrUpdate(.saveToPictures, saveToPictures.toString());
    ref.invalidate(syncSettingsProvider);
  }
}
