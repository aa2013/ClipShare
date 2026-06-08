import 'settings_section_view_base.dart';

class SettingsSyncPage extends SettingsSectionView {
  SettingsSyncPage({super.key, super.embedded}) : super(section: SettingsSection.sync);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.syncSettingsGroupName.tr,
          icon: const Icon(Icons.sync_rounded),
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
                TranslationKey.syncSettingsAutoSyncMissingDataTitle,
                TranslationKey.syncSettingsAutoSyncMissingDataDesc,
              ],
              title: Text(
                TranslationKey.syncSettingsAutoSyncMissingDataTitle.tr,
                maxLines: 1,
              ),
              description: Text(TranslationKey.syncSettingsAutoSyncMissingDataDesc.tr),
              value: appConfig.autoSyncMissingData,
              show: (v) => true,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    HapticFeedback.mediumImpact();
                    appConfig.setAutoSyncMissingData(checked);
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
              value: appConfig.reCopyOnScreenUnlocked,
              show: (v) => Platform.isAndroid,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    HapticFeedback.mediumImpact();
                    appConfig.setReCopyOnScreenUnlocked(checked);
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
              value: appConfig.saveToPictures,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    HapticFeedback.mediumImpact();
                    if (checked) {
                      if (Platform.isAndroid) {
                        var path = "${Constants.androidPicturesPath}/${Constants.appName}";
                        var res = await PermissionHelper.testAndroidStoragePerm(path);
                        if (res) {
                          appConfig.setSaveToPictures(true);
                          return;
                        }
                        DialogController? dialog;
                        dialog = await Global.showTipsDialog(
                          context: context,
                          text: TranslationKey.syncSettingsStoreImg2PicturesNoPermText.tr,
                          showCancel: true,
                          onOk: () async {
                            await dialog!.close();
                            await PermissionHelper.reqAndroidStoragePerm(path);
                            if (!await PermissionHelper.testAndroidStoragePerm(path)) {
                              appConfig.setSaveToPictures(false);
                              Global.showTipsDialog(
                                context: context,
                                text: TranslationKey.syncSettingsStoreImg2PicturesCancelPerm.tr,
                              );
                            } else {
                              appConfig.setSaveToPictures(true);
                            }
                          },
                          okText: TranslationKey.dialogAuthorizationButtonText.tr,
                        );
                      } else {
                        if (!await PermissionHelper.checkIOSPhotoPermission() && !await PermissionHelper.reqIOSPhotoPermission()) {
                          appConfig.setSaveToPictures(false);
                          Global.showTipsDialog(
                            context: context,
                            text: TranslationKey.noPhotoPermission.tr,
                            onOk: () {
                              openAppSettings();
                            },
                          );
                        } else {
                          appConfig.setSaveToPictures(true);
                        }
                      }
                    } else {
                      appConfig.setSaveToPictures(false);
                    }
                  },
                );
              },
              show: (v) => Platform.isAndroid || Platform.isIOS,
            ),
            SettingCard(
              searchKeys: const [
                TranslationKey.syncSettingsStoreFilePathTitle,
                TranslationKey.doubleClick2OpenPath,
              ],
              title: Text(
                TranslationKey.syncSettingsStoreFilePathTitle.tr,
                maxLines: 1,
              ),
              description: Visibility(
                visible: PlatformExt.isDesktop,
                replacement: Text(appConfig.fileStorePath),
                child: Tooltip(
                  message: TranslationKey.doubleClick2OpenPath.tr,
                  child: Text(appConfig.fileStorePath),
                ),
              ),
              value: false,
              action: (v) {
                return TextButton(
                  onPressed: () async {
                    String? directory = await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
                    if (directory != null) {
                      if (!FileUtil.testWriteable(directory)) {
                        Global.showTipsDialog(context: context, text: TranslationKey.unWriteablePathTips.tr);
                        return;
                      }
                      appConfig.setFileStorePath(directory);
                    }
                  },
                  child: Text(
                    TranslationKey.selection.tr,
                    maxLines: 1,
                  ),
                );
              },
              onDoubleTap: () async {
                final dir = Directory(appConfig.fileStorePath);
                if (!await dir.exists()) {
                  await dir.create(recursive: true);
                }
                await OpenFile.open(
                  appConfig.fileStorePath,
                );
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
              value: appConfig.autoCopyImageAfterSync,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    appConfig.setAutoCopyImageAfterSync(checked);
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
              show: (v) => Platform.isAndroid,
              value: appConfig.autoCopyImageAfterScreenShot,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    appConfig.setAutoCopyImageAfterScreenShot(checked);
                    final clipboardService = Get.find<ClipboardService>();
                    if (checked) {
                      clipboardService.startListenScreenshot();
                    } else {
                      clipboardService.stopListenScreenshot();
                    }
                  },
                );
              },
            ),
            SettingCard(
              searchKeys: const [TranslationKey.cleanData],
              title: Row(
                children: [
                  Text(
                    TranslationKey.cleanData.tr,
                    maxLines: 1,
                  ),
                ],
              ),
              value: null,
              action: (v) => IconButton(
                onPressed: controller.gotoCleanDataPage,
                icon: arrowForwardIcon,
              ),
              onTap: controller.gotoCleanDataPage,
            ),
            SettingCard<int>(
              searchKeys: const [
                TranslationKey.syncOutDateSettingTitle,
                TranslationKey.syncOutDateSettingDesc,
              ],
              title: Text(TranslationKey.syncOutDateSettingTitle.tr),
              description: Text(TranslationKey.syncOutDateSettingDesc.tr),
              value: appConfig.syncOutdateLimitTime,
              action: (v) => Text(v == 0 ? TranslationKey.noLimits.tr : v.timeSpanStr),
              onTap: () {
                Global.showDialog(
                  context,
                  OutdateTimeInputDialog(
                    initValue: appConfig.syncOutdateLimitTime,
                    onConfirm: (value) {
                      appConfig.setNewPairedDeviceSyncOldDataLimitTime(value);
                    },
                  ),
                );
              },
            ),
    ];
  }
}
