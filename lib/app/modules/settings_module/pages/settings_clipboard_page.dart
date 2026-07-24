import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'settings_section_view_base.dart';
import 'dart:io';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class SettingsClipboardPage extends SettingsSectionView {
  SettingsClipboardPage({super.key, super.embedded}) : super(section: SettingsSection.clipboard);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.clipboardSettingsGroupName.tr,
          icon: const Icon(MdiIcons.clipboardOutline),
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
          TranslationKey.stopListeningOnScreenClosedSettingTitle,
          TranslationKey.stopListeningOnScreenClosedSettingDesc,
        ],
        title: Text(
          TranslationKey.stopListeningOnScreenClosedSettingTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.stopListeningOnScreenClosedSettingDesc.tr),
        value: appConfig.stopListeningOnScreenClosed,
        show: (v) => Platform.isAndroid,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              appConfig.setStopListeningOnScreenClosed(checked);
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
            if (Platform.isAndroid)
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
                    onTap: () async {
                      Global.showTipsDialog(
                        context: context,
                        text: TranslationKey.clipboardSettingsSourceRecordDialogContent.tr,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        description: Platform.isAndroid ? Text(TranslationKey.clipboardSettingsSourceRecordAndroidDesc.tr) : null,
        value: appConfig.sourceRecord,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              appConfig.setEnableSourceRecord(checked);
              if (Platform.isAndroid && checked && !controller.hasAccessibilityPerm.value && !appConfig.ignoreAccessibility) {
                Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.noAccessibilityPermTips.tr,
                  showCancel: true,
                  okText: TranslationKey.goAuthorize.tr,
                  onOk: () {
                    controller.requestAccessibilityPermissionAndRefresh();
                  },
                  showNeutral: true,
                  neutralText: TranslationKey.notNow.tr,
                  onNeutral: () {
                    appConfig.ignoreAccessibility = true;
                  },
                );
              }
            },
          );
        },
        show: (v) => !Platform.isIOS,
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
                onTap: () async {
                  Global.showTipsDialog(
                    context: context,
                    text: TranslationKey.clipboardSettingsSourceRecordViaDumpsysDialogContent.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc.tr),
        value: appConfig.sourceRecordViaDumpsys,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              HapticFeedback.mediumImpact();
              appConfig.setEnableSourceRecordViaDumpsys(checked);
            },
          );
        },
        show: (v) => Platform.isAndroid && appConfig.sourceRecord,
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
                onTap: () async {
                  Global.showTipsDialog(
                    context: context,
                    selectable: true,
                    text: TranslationKey.sendBroadcastOnAddDataTips.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.sendBroadcastOnAddDataDesc.tr),
        value: appConfig.sendBroadcastOnAdd,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              HapticFeedback.mediumImpact();
              appConfig.setSendBroadcastOnAdd(checked);
            },
          );
        },
        show: (v) => Platform.isAndroid,
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
                Global.showTipsDialog(
                  context: context,
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
        value: appConfig.isExcludeFormat,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) {
              HapticFeedback.mediumImpact();
              appConfig.setExcludeFormat(checked);
            },
          );
        },
        show: (v) => Platform.isWindows,
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
        value: appConfig.recordMaxLength,
        action: (v) {
          if (v <= 0) {
            return Text(TranslationKey.noLimits.tr);
          }
          return Text("$v ${TranslationKey.unitWord.tr}");
        },
        onTap: () {
          Global.showDialog(
            context,
            TextEditDialog(
              title: TranslationKey.recordMaxLength.tr,
              labelText: TranslationKey.length.tr,
              initStr: "${appConfig.recordMaxLength <= 0 ? '' : appConfig.recordMaxLength}",
              verify: (str) {
                var n = int.tryParse(str);
                if (n == null || n < 0) return false;
                return true;
              },
              errorText: TranslationKey.mustGreaterThanZero.tr,
              onOk: (str) async {
                var n = str.toInt();
                await appConfig.setRecordMaxLength(n);
              },
            ),
          );
        },
      ),
    ];
  }
}
