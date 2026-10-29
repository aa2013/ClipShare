import 'dart:io';

import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/features/logs/pages/log_detail_page.dart';
import 'package:clipshare/features/logs/providers/log_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _tag = 'LogListView';

/// 日志文件列表，支持刷新、清空、生成 Android 日志与打开详情。
class LogListView extends ConsumerWidget {
  final bool showHeader;
  final EdgeInsetsGeometry padding;

  const LogListView({
    super.key,
    this.showHeader = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        final logs = ref.read(logsProvider.notifier);
        await logs.refresh();
      },
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            if (showHeader)
              Padding(
                padding: 10.insetH,
                child: const _LogListHeader(),
              ),
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                child: TextButton(
                  onPressed: () => _generateAndroidLog(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.article, color: Colors.blueGrey),
                      const SizedBox(width: 5),
                      Text(TranslationKey.generateTodayAndroidLog.tr),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: logsAsync.when(
                loading: () => const Loading(),
                error: (error, stack) => EmptyContent(description: error.toString()),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Stack(
                      children: [
                        ListView(),
                        const EmptyContent(),
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      return Column(
                        children: [
                          InkWell(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      logs[i].fileName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(logs[i].lengthSync().sizeStr),
                                ],
                              ),
                            ),
                            onTap: () => _openLogDetail(context, ref, logs[i]),
                          ),
                          Visibility(
                            visible: i != logs.length - 1,
                            child: const Divider(
                              indent: 16,
                              endIndent: 16,
                              height: 1,
                              thickness: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开日志详情：小屏走 go_router，大屏沿用通用抽屉。
  Future<void> _openLogDetail(BuildContext context, WidgetRef ref, File file) async {
    if (context.isCompactScreen) {
      await context.pushNamed(
        AppRoutes.logDetail.name,
        extra: LogDetailRouteArgs(file: file),
      );
      return;
    }
    final drawerNotifier = ref.read(drawerProvider.notifier);
    drawerNotifier.resetWidth(context.media.size.width * 0.8);
    final drawer = ref.read(drawerProvider);
    drawer.controller.push(
      LogDetailPage(file: file),
      () {
        drawerNotifier.resetWidth();
        return true;
      },
    );
  }

  /// 生成当天的 Android 系统日志并刷新列表。
  Future<void> _generateAndroidLog(BuildContext context, WidgetRef ref) async {
    final dialog = dialogManager.loading(context, loadingText: TranslationKey.pleaseWait.tr);
    var success = false;
    try {
      await Future.delayed(500.ms);
      await logger.writeAndroidLogToday();
      final logs = ref.read(logsProvider.notifier);
      await logs.refresh();
      success = true;
    } catch (err, stack) {
      logger.error(_tag, err, stack);
    } finally {
      await dialog.close();
    }
    if (!context.mounted) {
      return;
    }
    if (success) {
      snackbar.success(context, TranslationKey.done.tr);
    } else {
      snackbar.error(context, TranslationKey.failed.tr);
    }
  }
}

class _LogListHeader extends StatelessWidget {
  const _LogListHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(TranslationKey.logPageAppBarTitle.tr),
        const LogClearButton(),
      ],
    );
  }
}

class LogClearButton extends ConsumerWidget {
  const LogClearButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        late DialogController dialog;
        dialog = dialogManager.open(
          context,
          AlertDialog(
            title: Text(TranslationKey.tips.tr),
            content: Text(TranslationKey.logSettingsDeleteLogFilesDialogContent.tr),
            actions: [
              TextButton(
                onPressed: () {
                  dialog.close();
                },
                child: Text(TranslationKey.dialogCancelText.tr),
              ),
              TextButton(
                onPressed: () async {
                  final logs = ref.read(logsProvider.notifier);
                  await logs.clear();
                  await dialog.close();
                },
                child: Text(TranslationKey.dialogConfirmText.tr),
              ),
            ],
          ),
        );
      },
      tooltip: TranslationKey.clear.tr,
      icon: const Icon(
        Icons.cleaning_services_rounded,
        color: Colors.blueGrey,
        size: 17,
      ),
    );
  }
}
