import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/settings/security/security_settings_provider.dart';
import 'package:clipshare/features/auth/providers/app_lock_provider.dart';
import 'package:clipshare/features/auth/widgets/auth_password_input.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/utils/dh_key_validator.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/radio_group.dart';
import 'package:clipshare/shared/widgets/dialogs/single_select_dialog.dart';
import 'package:clipshare/shared/widgets/dialogs/text_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 重新验证时长可选项（分钟），0 表示切后台后立即重验
List<RadioData<int>> get _authBackEndTimeSelections => [
  RadioData(value: 0, label: TranslationKey.immediately.tr),
  RadioData(value: 1, label: '1 ${TranslationKey.minute.tr}'),
  RadioData(value: 2, label: '2 ${TranslationKey.minute.tr}'),
  RadioData(value: 5, label: '5 ${TranslationKey.minute.tr}'),
  RadioData(value: 10, label: '10 ${TranslationKey.minute.tr}'),
  RadioData(value: 30, label: '30 ${TranslationKey.minute.tr}'),
];

/// 打开设置应用密码页（二次输入确认），确认后以 MD5 值保存
void _gotoSetPwd(BuildContext context, WidgetRef ref) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AuthPasswordInput(
        onFinished: (first, second) => first == second,
        onOk: (input) {
          unawaited(_saveAppPassword(ref, input));
          return true;
        },
        again: true,
        showCancelBtn: true,
      ),
    ),
  );
}

/// 保存应用密码（MD5 值）
Future<void> _saveAppPassword(WidgetRef ref, String input) async {
  final configDao = ref.read(appDbProvider).requireValue.configDao;
  await configDao.addOrUpdate(ConfigKey.appPassword, CryptoUtil.toMD5(input));
  ref.invalidate(securitySettingsProvider);
}

/// 保存 DH 加密密钥并失效相关配置缓存，使传输握手使用新密钥
Future<void> _saveDhEncryptKey(WidgetRef ref, String key) async {
  final configDao = ref.read(appDbProvider).requireValue.configDao;
  await configDao.addOrUpdate(ConfigKey.dhEncryptKey, key);
  ref.invalidate(securitySettingsProvider);
  ref.invalidate(deviceSettingsProvider);
}

/// 打开修改应用密码流程：已有密码时先验证，验证通过后再设置新密码
void _changeAppPassword(BuildContext context, WidgetRef ref) {
  final appLock = ref.read(appLockProvider.notifier);
  appLock
      .authenticate(
        localizedReason: TranslationKey.authenticationPageTitle.tr,
        lock: false,
      )
      .then((result) {
        if (!context.mounted) {
          return;
        }
        if (result != null) {
          _gotoSetPwd(context, ref);
        }
      });
}

class SettingsSecurityPage extends SettingsSectionView {
  const SettingsSecurityPage({super.key, super.embedded}) : super(section: SettingsSection.security);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.securitySettingsGroupName.tr,
        icon: const Icon(Icons.fingerprint_outlined),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final securitySettings = ref.watch(securitySettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final appPassword = securitySettings.appPassword;
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
        value: securitySettings.useAuthentication,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              HapticFeedback.mediumImpact();
              if (appPassword == null && checked) {
                dialogManager.tips(
                  context,
                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                  actions: DialogActions(
                    cancel: const DialogAction(),
                    confirm: DialogAction(
                      text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                      onPressed: () => _gotoSetPwd(context, ref),
                    ),
                  ),
                );
                await configDao.addOrUpdate(ConfigKey.useAuthentication, false.toString());
              } else {
                await configDao.addOrUpdate(ConfigKey.useAuthentication, checked.toString());
              }
              ref.invalidate(securitySettingsProvider);
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
        description: Text(appPassword == null ? TranslationKey.createAppPwd.tr : TranslationKey.changeAppPwd.tr),
        value: appPassword,
        action: (v) {
          return TextButton(
            onPressed: () {
              if (appPassword == null) {
                _gotoSetPwd(context, ref);
              } else {
                _changeAppPassword(context, ref);
              }
            },
            child: Text(appPassword == null ? TranslationKey.create.tr : TranslationKey.change.tr),
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
        value: securitySettings.appRevalidateDuration,
        onTap: () {
          DialogController? dialog;
          dialog = SingleSelectDialog.show(
            context: context,
            defaultValue: securitySettings.appRevalidateDuration,
            onSelected: (duration) {
              Future.delayed(100.ms).then(
                (value) async {
                  await configDao.addOrUpdate(ConfigKey.appRevalidateDuration, duration.toString());
                  ref.invalidate(securitySettingsProvider);
                  await dialog!.close();
                },
              );
            },
            selections: _authBackEndTimeSelections,
            title: Text(TranslationKey.securitySettingsReverificationTitle.tr),
          );
        },
        action: (v) {
          var duration = securitySettings.appRevalidateDuration;
          return Text(
            duration <= 0 ? TranslationKey.immediately.tr : TranslationKey.securitySettingsReverificationValue.trParams({'value': duration.toString()}),
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
                dialogManager.tips(context, text: TranslationKey.dhKeySettingTips.tr);
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
        value: securitySettings.dhEncryptKey,
        action: (v) {
          return TextButton(
            child: Text(v.isNullOrEmpty ? TranslationKey.configure.tr : TranslationKey.change.tr),
            onPressed: () {
              if (appPassword == null) {
                dialogManager.tips(
                  context,
                  text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent.tr,
                  actions: DialogActions(
                    cancel: const DialogAction(),
                    confirm: DialogAction(
                      text: TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText.tr,
                      onPressed: () => _gotoSetPwd(context, ref),
                    ),
                  ),
                );
                return;
              }

              final appLock = ref.read(appLockProvider.notifier);
              appLock
                  .authenticate(
                    localizedReason: TranslationKey.authenticationPageTitle.tr,
                    lock: false,
                  )
                  .then((result) {
                    if (!context.mounted) {
                      return;
                    }
                    if (result == null) {
                      snackbar.warn(context, TranslationKey.authFailed.tr);
                      return;
                    }
                    dialogManager.open(
                      context,
                      TextEditDialog(
                        title: TranslationKey.encryptKey.tr,
                        labelText: TranslationKey.pleaseInput.tr,
                        initStr: securitySettings.dhEncryptKey.isEmpty ? '' : securitySettings.dhEncryptKey,
                        verify: (str) {
                          final dhAesKey = ref.read(deviceSettingsProvider).requireValue.dhAesKey;
                          return DhKeyValidator.verify(str, hasCurrentKey: (dhAesKey ?? '').isNotEmpty);
                        },
                        errorText: TranslationKey.encryptKeyErrorTip.tr,
                        onOk: (str) async {
                          if (str.isEmpty) {
                            dialogManager.tips(
                              context,
                              text: TranslationKey.confirmClearEncryptKey.tr,
                              actions: DialogActions(
                                cancel: const DialogAction(),
                                confirm: DialogAction(
                                  onPressed: () async {
                                    await _saveDhEncryptKey(ref, str);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    snackbar.success(context, TranslationKey.clearSuccess.tr);
                                  },
                                ),
                              ),
                            );
                          } else {
                            await _saveDhEncryptKey(ref, str);
                            if (!context.mounted) {
                              return;
                            }
                            snackbar.success(context, TranslationKey.saveSuccess.tr);
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
