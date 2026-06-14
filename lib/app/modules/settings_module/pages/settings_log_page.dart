import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/log_module/log_list_view.dart';

import 'settings_section_view_base.dart';

class SettingsLogPage extends SettingsSectionView {
  SettingsLogPage({super.key, super.embedded}) : super(section: SettingsSection.log);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      _buildLogSettingsGroup(context),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final logController = Get.isRegistered<LogController>() ? Get.find<LogController>() : Get.put(LogController());
    final padding = embedded ? const EdgeInsets.fromLTRB(18, 0, 18, 12) : const EdgeInsets.fromLTRB(8, 12, 8, 12);
    return Column(
      children: [
        Padding(
          padding: padding,
          child: Column(
            children: buildCards(context),
          ),
        ),
        Expanded(
          child: LogListView(
            controller: logController,
            showHeader: true,
            padding: embedded ? const EdgeInsets.fromLTRB(18, 0, 18, 18) : const EdgeInsets.fromLTRB(8, 0, 8, 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLogSettingsGroup(BuildContext context) {
    return Obx(
      () => SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.logSettingsGroupName.tr,
        icon: const Icon(Icons.bug_report_outlined),
        cardList: buildSettingEntries(context),
      ),
    );
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.logSettingsEnableTitle,
          TranslationKey.logSettingsEnableDesc,
          TranslationKey.openFolder,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.logSettingsEnableTitle.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: TranslationKey.openFolder.tr,
              child: GestureDetector(
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.open_in_new_outlined,
                    color: Colors.blueGrey,
                    size: 17,
                  ),
                ),
                onTap: () async {
                  Directory(appConfig.logsDirPath).createSync(recursive: true);
                  try {
                    await OpenFile.open(appConfig.logsDirPath);
                  } catch (e) {
                    logger.error(logTag, e);
                  }
                },
              ),
            ),
          ],
        ),
        description: Obx(() {
          final tmp = controller.updater;
          final emptyStr = tmp.value != 0 ? "" : "";
          final size = FileUtil.getDirectorySize(appConfig.logsDirPath);
          return Text(
            "${TranslationKey.logSettingsEnableDesc.trParams({
              "size": size.sizeStr,
            })}$emptyStr",
          );
        }),
        value: appConfig.enableLogsRecord,
        onTap: () => _toggleLogsRecord(!appConfig.enableLogsRecord),
        action: (v) {
          return Switch(
            value: v,
            onChanged: _toggleLogsRecord,
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.logSettingsAutoUploadCrashLogTitle,
          TranslationKey.logSettingsAutoUploadCrashLogDesc,
          TranslationKey.logSettingsAutoUploadCrashLogTips,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.logSettingsAutoUploadCrashLogTitle.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                Global.showTipsDialog(context: context, text: TranslationKey.logSettingsAutoUploadCrashLogTips.tr);
              },
              child: const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 15,
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.logSettingsAutoUploadCrashLogDesc.tr),
        value: appConfig.enableAutoUploadCrashLogs,
        onTap: () => _toggleAutoUploadCrashLogs(!appConfig.enableAutoUploadCrashLogs),
        action: (v) {
          return Switch(
            value: v,
            onChanged: _toggleAutoUploadCrashLogs,
          );
        },
        show: (v) => Platform.isAndroid,
      ),
    ];
  }

  void _toggleLogsRecord(bool checked) {
    HapticFeedback.mediumImpact();
    appConfig.setEnableLogsRecord(checked);
    controller.updater.value++;
  }

  void _toggleAutoUploadCrashLogs(bool checked) {
    HapticFeedback.mediumImpact();
    appConfig.setEnableAutoUploadCrashLogs(checked);
    androidChannelService.setAutoReportCrashes(checked);
  }
}
