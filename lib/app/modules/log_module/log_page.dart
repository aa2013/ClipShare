import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/views/log_detail_page.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/global.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LogPage extends GetView<LogController> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final appConfig = Get.find<ConfigService>();
    final clearLogsButton = IconButton(
      onPressed: () {
        late DialogController dialog;
        dialog = Global.showDialog(
          context,
          AlertDialog(
            title: Text(TranslationKey.tips.tr),
            content: Text(TranslationKey.logSettingsAckDelLogFiles.tr),
            actions: [
              TextButton(
                onPressed: () {
                  dialog.close();
                },
                child: Text(TranslationKey.dialogCancelText.tr),
              ),
              TextButton(
                onPressed: () {
                  FileUtil.deleteDirectoryFiles(
                    appConfig.logsDirPath,
                  );
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
    final showAppBar = appConfig.isSmallScreen;
    final appBarRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(TranslationKey.logPageAppBarTitle.tr),
        clearLogsButton,
      ],
    );
    final content = RefreshIndicator(
      onRefresh: () {
        return Future.delayed(300.ms, () {
          controller.loadLogFileList();
        });
      },
      child: Column(
        children: [
          if (!appConfig.isSmallScreen)
            Padding(
              padding: 10.insetH,
              child: appBarRow,
            ),
          if (Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextButton(
                onPressed: () async {
                  var dialog = Global.showLoadingDialog(context: context, loadingText: TranslationKey.pleaseWait.tr);
                  await Future.delayed(500.ms);
                  Log.writeAndroidLogToday().whenComplete(() {
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
                                    Text(controller.logs[i].fileName),
                                    Text(
                                      controller.logs[i].lengthSync().sizeStr,
                                    ),
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
    );
    if (showAppBar) {
      final appBar = AppBar(
        title: appBarRow,
        backgroundColor: currentTheme.colorScheme.inversePrimary,
      );
      return Scaffold(
        appBar: showAppBar ? appBar : null,
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }
}
