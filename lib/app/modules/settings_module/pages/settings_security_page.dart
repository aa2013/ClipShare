import 'settings_section_view_base.dart';

class SettingsSecurityPage extends SettingsSectionView {
  SettingsSecurityPage({super.key, super.embedded}) : super(section: SettingsSection.security);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.securitySettingsGroupName.tr,
          icon: const Icon(Icons.fingerprint_outlined),
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
          TranslationKey.securitySettingsEnableSecurityTitle,
          TranslationKey.securitySettingsEnableSecurityDesc,
        ],
        title: Text(
          TranslationKey.securitySettingsEnableSecurityTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.securitySettingsEnableSecurityDesc.tr),
        value: appConfig.useAuthentication,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              if (appConfig.appPassword == null && checked) {
                Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                  onOk: controller.gotoSetPwd,
                  okText: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                  showCancel: true,
                );
                appConfig.setUseAuthentication(false);
              } else {
                appConfig.setUseAuthentication(checked);
              }
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.securitySettingsEnableSecurityAppPwdModifyTitle,
          TranslationKey.createAppPwd,
          TranslationKey.changeAppPwd,
        ],
        title: Text(
          TranslationKey.securitySettingsEnableSecurityAppPwdModifyTitle.tr,
          maxLines: 1,
        ),
        description: Text(appConfig.appPassword == null ? TranslationKey.createAppPwd.tr : TranslationKey.changeAppPwd.tr),
        value: appConfig.appPassword,
        action: (v) {
          return TextButton(
            onPressed: () {
              if (appConfig.appPassword == null) {
                controller.gotoSetPwd();
              } else {
                appConfig.authenticating.value = true;
                final homeController = Get.find<HomeController>();
                homeController
                    .gotoAuthenticationPage(
                      TranslationKey.authenticationPageTitle.tr,
                      lock: false,
                    )
                    ?.then((v) {
                      if (v != null) {
                        controller.gotoSetPwd();
                      }
                    });
              }
            },
            child: Text(appConfig.appPassword == null ? TranslationKey.create.tr : TranslationKey.change.tr),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.securitySettingsReverificationTitle,
          TranslationKey.securitySettingsReverificationDesc,
          TranslationKey.securitySettingsReverificationValue,
        ],
        title: Text(
          TranslationKey.securitySettingsReverificationTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.securitySettingsReverificationDesc.tr),
        value: appConfig.appRevalidateDuration,
        onTap: () {
          DialogController? dialog;
          dialog = SingleSelectDialog.show(
            context: context,
            defaultValue: appConfig.appRevalidateDuration,
            onSelected: (duration) {
              Future.delayed(100.ms).then(
                (value) {
                  appConfig.setAppRevalidateDuration(duration);
                  dialog!.close();
                },
              );
            },
            selections: Constants.authBackEndTimeSelections,
            title: Text(TranslationKey.securitySettingsReverificationTitle.tr),
          );
        },
        action: (v) {
          var duration = appConfig.appRevalidateDuration;
          return Text(
            duration <= 0 ? TranslationKey.immediately.tr : TranslationKey.securitySettingsReverificationValue.trParams({"value": duration.toString()}),
          );
        },
      ),
      SettingCard<String>(
        searchKeys: const [
          TranslationKey.dhKeySettingName,
          TranslationKey.dhKeySettingDesc,
          TranslationKey.dhKeySettingTips,
          TranslationKey.encryptKey,
        ],
        title: Row(
          children: [
            Text(TranslationKey.dhKeySettingName.tr, maxLines: 1),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                Global.showTipsDialog(context: context, text: TranslationKey.dhKeySettingTips.tr);
              },
              child: const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 15,
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.dhKeySettingDesc.tr),
        value: appConfig.dhEncryptKey,
        action: (v) {
          return TextButton(
            child: Text(v.isNullOrEmpty ? TranslationKey.configure.tr : TranslationKey.change.tr),
            onPressed: () {
              if (appConfig.appPassword == null) {
                Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                  onOk: controller.gotoSetPwd,
                  okText: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                  showCancel: true,
                );
                return;
              }

              appConfig.authenticating.value = true;
              final homeController = Get.find<HomeController>();
              homeController
                  .gotoAuthenticationPage(
                    TranslationKey.authenticationPageTitle.tr,
                    lock: false,
                  )
                  ?.then((v) {
                    if (v == null) {
                      Global.showSnackBarWarn(text: TranslationKey.authFailed.tr, context: context);
                      return;
                    }
                    Global.showDialog(
                      context,
                      TextEditDialog(
                        title: TranslationKey.encryptKey.tr,
                        labelText: TranslationKey.pleaseInput.tr,
                        initStr: appConfig.dhEncryptKey.isEmpty ? '' : appConfig.dhEncryptKey,
                        verify: (str) {
                          return (str.isEmpty && (appConfig.dhAesKey ?? '').isNotEmpty) || str.replaceAll('\\s+', '').length >= 8;
                        },
                        errorText: TranslationKey.encryptKeyErrorTip.tr,
                        onOk: (str) async {
                          if (str.isEmpty) {
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.confirmClearEncryptKey.tr,
                              showCancel: true,
                              onOk: () async {
                                await appConfig.setDHEncryptKey(str);
                                Global.showSnackBarSuc(text: TranslationKey.clearSuccess.tr, context: context);
                              },
                            );
                          } else {
                            await appConfig.setDHEncryptKey(str);
                            Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
                          }
                        },
                      ),
                    );
                  });
            },
          );
        },
      ),
    ];
  }
}
