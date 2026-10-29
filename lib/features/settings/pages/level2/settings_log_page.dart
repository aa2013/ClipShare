import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/log/log_settings_provider.dart';
import 'package:clipshare/features/logs/providers/log_provider.dart';
import 'package:clipshare/features/logs/widgets/log_list_view.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file_plus/open_file_plus.dart';

class SettingsLogPage extends SettingsSectionView {
  static const tag = 'SettingsLogPage';

  const SettingsLogPage({super.key, super.embedded}) : super(section: SettingsSection.log);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      _buildLogSettingsGroup(context, ref),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = embedded ? const EdgeInsets.fromLTRB(18, 0, 18, 12) : const EdgeInsets.fromLTRB(8, 12, 8, 12);
    return _LogAutoRefreshScope(
      child: Column(
        children: [
          Padding(
            padding: padding,
            child: Column(
              children: buildCards(context, ref),
            ),
          ),
          Expanded(
            child: LogListView(
              showHeader: true,
              padding: embedded ? const EdgeInsets.fromLTRB(18, 0, 18, 18) : const EdgeInsets.fromLTRB(8, 0, 8, 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogSettingsGroup(BuildContext context, WidgetRef ref) {
    return SettingCardGroup(
      showHeader: showGroupHeader,
      groupName: TranslationKey.logSettingsGroupName.tr,
      icon: const Icon(Icons.bug_report_outlined),
      cardList: buildSettingEntries(context, ref),
    );
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final appPaths = ref.watch(appPathsProvider).requireValue;
    final logSettings = ref.watch(logSettingsProvider).requireValue;
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
                  await Directory(appPaths.logsDirPath).create(recursive: true);
                  try {
                    await OpenFile.open(appPaths.logsDirPath);
                  } catch (e) {
                    logger.error(tag, e);
                  }
                },
              ),
            ),
          ],
        ),
        description: Consumer(
          builder: (context, ref, child) {
            // 监听日志列表变化，清理日志后同步刷新目录占用大小
            ref.watch(logsProvider);
            final size = FileUtil.getDirectorySize(appPaths.logsDirPath);
            return Text(
              TranslationKey.logSettingsEnableDesc.trParams({
                'size': size.sizeStr,
              }),
            );
          },
        ),
        value: logSettings.enableLogsRecord,
        onTap: () => _toggleLogsRecord(ref, !logSettings.enableLogsRecord),
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) => _toggleLogsRecord(ref, checked),
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
                dialogManager.tips(context, text: TranslationKey.logSettingsAutoUploadCrashLogTips.tr);
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
        value: logSettings.enableAutoUploadCrashLogs,
        onTap: () => _toggleAutoUploadCrashLogs(ref, !logSettings.enableAutoUploadCrashLogs),
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) => _toggleAutoUploadCrashLogs(ref, checked),
          );
        },
        show: (v) => isAndroid,
      ),
    ];
  }

  Future<void> _toggleLogsRecord(WidgetRef ref, bool checked) async {
    await HapticFeedback.mediumImpact();
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(.enableLogsRecord, checked.toString());
    ref.invalidate(logSettingsProvider);
  }

  Future<void> _toggleAutoUploadCrashLogs(WidgetRef ref, bool checked) async {
    await HapticFeedback.mediumImpact();
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final androidChannel = ref.read(androidChannelProvider.notifier);
    await configDao.addOrUpdate(.enableAutoUploadCrashLogs, checked.toString());
    await androidChannel.setAutoReportCrashes(checked);
    ref.invalidate(logSettingsProvider);
  }
}

/// 日志页打开期间定时刷新日志列表与目录占用大小
class _LogAutoRefreshScope extends ConsumerStatefulWidget {
  final Widget child;

  const _LogAutoRefreshScope({required this.child});

  @override
  ConsumerState<_LogAutoRefreshScope> createState() => _LogAutoRefreshScopeState();
}

class _LogAutoRefreshScopeState extends ConsumerState<_LogAutoRefreshScope> {
  static const _refreshInterval = Duration(seconds: 5);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //定时触发 logsProvider.refresh()，列表与目录大小均随其状态重建
    _timer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(ref.read(logsProvider.notifier).refresh()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
