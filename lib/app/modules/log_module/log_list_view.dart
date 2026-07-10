import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogListView extends StatelessWidget {
  final LogController controller;
  final bool showHeader;
  final EdgeInsetsGeometry padding;

  const LogListView({
    super.key,
    required this.controller,
    this.showHeader = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return Future.delayed(300.ms, () {
          controller.loadLogFileList();
        });
      },
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            if (showHeader)
              Padding(
                padding: 10.insetH,
                child: _LogListHeader(controller: controller),
              ),
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                child: TextButton(
                  onPressed: () async {
                    var dialog = Global.showLoadingDialog(context: context, loadingText: TranslationKey.pleaseWait.tr);
                    await Future.delayed(500.ms);
                    logger.writeAndroidLogToday().whenComplete(() {
                      dialog.close();
                      controller.loadLogFileList();
                      Global.showSnackBarSuc(text: TranslationKey.done.tr, context: context);
                    });
                  },
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
              child: Obx(
                () => ConditionWidget(
                  visible: !controller.init.value,
                  replacement: Obx(
                    () => ConditionWidget(
                      visible: controller.logs.isEmpty,
                      replacement: ListView.builder(
                        itemCount: controller.logs.length,
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
                                          controller.logs[i].fileName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(controller.logs[i].lengthSync().sizeStr),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  final file = controller.logs[i];
                                  controller.gotoLogDetailPage(file);
                                },
                              ),
                              Visibility(
                                visible: i != controller.logs.length - 1,
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
                      ),
                      child: Stack(
                        children: [
                          ListView(),
                          EmptyContent(),
                        ],
                      ),
                    ),
                  ),
                  child: const Loading(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogListHeader extends StatelessWidget {
  final LogController controller;

  const _LogListHeader({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(TranslationKey.logPageAppBarTitle.tr),
        LogClearButton(controller: controller),
      ],
    );
  }
}

class LogClearButton extends StatelessWidget {
  final LogController controller;

  const LogClearButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    return IconButton(
      onPressed: () {
        late DialogController dialog;
        dialog = Global.showDialog(
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
                onPressed: () {
                  FileUtil.deleteDirectoryFiles(appConfig.logsDirPath);
                  controller.loadLogFileList();
                  dialog.close();
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
