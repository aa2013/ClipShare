import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/white_black_rule.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_apps/get_apps.dart';

class FilterRuleAddDialog extends StatefulWidget {
  final FilterRule? data;
  final WhiteBlackMode mode;
  final void Function(FilterRule rule) onDone;

  const FilterRuleAddDialog({
    super.key,
    required this.onDone,
    required this.mode,
    this.data,
  });

  @override
  State<StatefulWidget> createState() => _FilterRuleAddDialogState();
}

class _FilterRuleAddDialogState extends State<FilterRuleAddDialog> {
  final appConfig = Get.find<ConfigService>();
  final contentText = TextEditingController();
  final allLocalAppList = <LocalAppInfo>[].obs;
  final selectedAppList = <LocalAppInfo>[].obs;
  final ignoreCase = false.obs;
  final iconBytesMap = <String, Uint8List>{};
  final sourceService = Get.find<ClipboardSourceService>();
  late final bool isBlacklist;

  @override
  void initState() {
    super.initState();
    isBlacklist = widget.mode == WhiteBlackMode.black;
    if (widget.data != null) {
      contentText.text = widget.data!.content;
      ignoreCase.value = widget.data!.ignoreCase;
    }
    loadInstalledApps().then((_) {
      iconBytesMap.clear();
      for (var item in allLocalAppList) {
        iconBytesMap[item.appId] = base64Decode(item.iconB64);
      }
      if (widget.data != null) {
        selectedAppList.addAll((allLocalAppList.where((item) => widget.data!.appIds.contains(item.appId))));
      }
    });
  }

  Future<void> loadInstalledApps() async {
    await sourceService.loadInstalledApps();
    allLocalAppList.addAll(sourceService.installedApps);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isBlacklist ? TranslationKey.addBlacklistRule.tr : TranslationKey.addWhitelistRule.tr),
      content: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: contentText,
              autofocus: true,
              decoration: InputDecoration(
                labelText: TranslationKey.content.tr,
                hintText: TranslationKey.supportRegex.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            if (Platform.isAndroid) const SizedBox(height: 10),
            if (Platform.isAndroid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${TranslationKey.application.tr}: "),
                  RoundedChip(
                    avatar: const Icon(Icons.add),
                    label: Text(TranslationKey.selection.tr),
                    onPressed: () {
                      final page = AppSelectionPage(
                        loadDeviceName: (devId) => appConfig.device.name,
                        selectedIds: selectedAppList.map((app) => app.appId).toList(),
                        distinguishSystemApps: true,
                        loadAppInfos: () async {
                          return allLocalAppList.value;
                        },
                        onSelectedDone: (selected) {
                          selectedAppList.clear();
                          selectedAppList.addAll(selected);
                        },
                      );
                      if (appConfig.isSmallScreen) {
                        Get.to(page);
                      } else {
                        Get.dialog(DynamicSizeWidget(child: page));
                      }
                    },
                  ),
                ],
              ),
            if (Platform.isAndroid)
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(
                    () => Wrap(
                      children: selectedAppList.map((app) {
                        return Container(
                          margin: const EdgeInsets.only(right: 5, bottom: 5),
                          child: RoundedChip(
                            onPressed: () => {},
                            label: Text(app.name),
                            avatar: Image.memory(iconBytesMap[app.appId] ?? Uint8List(0)),
                            deleteIcon: const Icon(Icons.delete),
                            onDeleted: () {
                              selectedAppList.remove(app);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            Obx(
              () => Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: CheckboxListTile(
                  value: ignoreCase.value,
                  dense: true,
                  title: Text(TranslationKey.ignoreCase.tr),
                  onChanged: (checked) => ignoreCase.value = checked ?? false,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: Get.back, child: Text(TranslationKey.dialogCancelText.tr)),
            TextButton(
              onPressed: () {
                widget.onDone(
                  FilterRule(
                    content: contentText.text,
                    appIds: selectedAppList.map((item) => item.appId).toSet(),
                    enable: true,
                    needSync: false,
                    ignoreCase: ignoreCase.value,
                  ),
                );
              },
              child: Text(widget.data == null ? TranslationKey.add.tr : TranslationKey.modify.tr),
            ),
          ],
        ),
      ],
    );
  }
}
