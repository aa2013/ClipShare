
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/services/permission/permission_info_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/widgets/dialogs/text_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsClipboardPage extends SettingsSectionView {
  const SettingsClipboardPage({super.key, super.embedded}) : super(section: SettingsSection.clipboard);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.clipboardSettingsGroupName.tr,
        icon: const Icon(MdiIcons.clipboardOutline),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final clipboardSettings = ref.watch(clipboardSettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.stopListeningOnScreenClosedSettingTitle,
          TranslationKey.stopListeningOnScreenClosedSettingDesc,
        ],
        title: Text(
          TranslationKey.stopListeningOnScreenClosedSettingTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.stopListeningOnScreenClosedSettingDesc.tr),
        value: clipboardSettings.stopListeningOnScreenClosed,
        show: (v) => isAndroid,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              configDao.addOrUpdate(.stopListeningOnScreenClosed, checked.toString());
              ref.invalidate(clipboardSettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.clipboardSettingsSourceRecordTitle,
          TranslationKey.clipboardSettingsSourceRecordAndroidDesc,
          TranslationKey.clipboardSettingsSourceRecordTitleTooltip,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.clipboardSettingsSourceRecordTitle.tr,
              maxLines: 1,
            ),
            if (isAndroid)
              Container(
                margin: const EdgeInsets.only(left: 5),
                child: Tooltip(
                  message: TranslationKey.clipboardSettingsSourceRecordTitleTooltip.tr,
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                        size: 15,
                      ),
                    ),
                    onTap: () {
                      dialogManager.tips(
                        context,
                        text: TranslationKey.clipboardSettingsSourceRecordDialogContent.tr,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        description: isAndroid ? Text(TranslationKey.clipboardSettingsSourceRecordAndroidDesc.tr) : null,
        value: clipboardSettings.sourceRecord,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await configDao.addOrUpdate(.sourceRecord, checked.toString());
              ref.invalidate(clipboardSettingsProvider);
              if (!isAndroid) {
                return;
              }
              if (!checked) {
                return;
              }
              final appState = ref.read(appStateProvider);
              if (appState.ignoreAccessibility) {
                return;
              }
              await HapticFeedback.mediumImpact();
              final permission = ref.read(permissionInfoProvider).requireValue;
              if (context.mounted && !permission.hasAccessibilityPermission) {
                await dialogManager.tips(
                  context,
                  text: TranslationKey.noAccessibilityPermTips.tr,
                  actions: DialogActions(
                    confirm: DialogAction(
                      text: TranslationKey.goAuthorize.tr,
                      onPressed: () {
                        //todo 权限请求
                        // controller.requestAccessibilityPermissionAndRefresh();
                      },
                    ),
                    cancel: const DialogAction(),
                    neutral: DialogAction(
                      text: TranslationKey.notNow.tr,
                      onPressed: () {
                        ref.read(appStateProvider.notifier).updateIgnoreAccessibility(true);
                      },
                    ),
                  ),
                );
              }
            },
          );
        },
        show: (v) => !isIOS,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitle,
          TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc,
          TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltip,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitle.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltip.tr,
              child: GestureDetector(
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                    size: 15,
                  ),
                ),
                onTap: () {
                  dialogManager.tips(
                    context,
                    text: TranslationKey.clipboardSettingsSourceRecordViaDumpsysDialogContent.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc.tr),
        value: clipboardSettings.sourceRecordViaDumpsys,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.sourceRecordViaDumpsys, checked.toString());
              ref.invalidate(clipboardSettingsProvider);
            },
          );
        },
        show: (v) => isAndroid && clipboardSettings.sourceRecord,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.sendBroadcastOnAddData,
          TranslationKey.sendBroadcastOnAddDataDesc,
          TranslationKey.sendBroadcastOnAddDataTips,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.sendBroadcastOnAddData.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: TranslationKey.explain.tr,
              child: GestureDetector(
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                    size: 15,
                  ),
                ),
                onTap: () {
                  dialogManager.tips(
                    context,
                    selectable: true,
                    text: TranslationKey.sendBroadcastOnAddDataTips.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.sendBroadcastOnAddDataDesc.tr),
        value: clipboardSettings.sendBroadcastOnAdd,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              if (!isAndroid) {
                return;
              }
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.sendBroadcastOnAdd, checked.toString());
              ref.invalidate(clipboardSettingsProvider);
            },
          );
        },
        show: (v) => isAndroid,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.excludePrivateFormat,
          TranslationKey.excludePrivateFormatTips,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.excludePrivateFormat.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                dialogManager.tips(
                  context,
                  selectable: true,
                  text: TranslationKey.excludePrivateFormatTips.tr,
                );
              },
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blueGrey,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.excludePrivateFormatDesc.tr),
        value: clipboardSettings.isExcludeFormat,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              if (!isWindows) {
                return;
              }
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.excludeFormat, checked.toString());
              final clipboardService = ref.read(clipboardServiceProvider).requireValue;
              await clipboardService.setExcludeFormat(checked);
            },
          );
        },
        show: (v) => isWindows,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.recordMaxLength,
          TranslationKey.recordMaxLengthTips,
          TranslationKey.noLimits,
          TranslationKey.length,
        ],
        title: Text(
          TranslationKey.recordMaxLength.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.recordMaxLengthTips.tr),
        value: clipboardSettings.recordMaxLength,
        action: (v) {
          if (v <= 0) {
            return Text(TranslationKey.noLimits.tr);
          }
          return Text('$v ${TranslationKey.unitWord.tr}');
        },
        onTap: () {
          dialogManager.open(
            context,
            TextEditDialog(
              title: TranslationKey.recordMaxLength.tr,
              labelText: TranslationKey.length.tr,
              initStr: "${clipboardSettings.recordMaxLength <= 0 ? '' : clipboardSettings.recordMaxLength}",
              verify: (str) {
                var n = int.tryParse(str);
                if (n == null || n < 0) return false;
                return true;
              },
              errorText: TranslationKey.mustGreaterThanZero.tr,
              onOk: (limit) async {
                final _ = limit.toInt();
                await configDao.addOrUpdate(.recordMaxLength, limit.toString());
                ref.invalidate(clipboardSettingsProvider);
              },
            ),
          );
        },
      ),
    ];
  }
}
