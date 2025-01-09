import 'dart:convert';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/views/log_detail_page.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LogPage extends GetView<LogController> {
  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: Text(TranslationKey.logPageAppBarTitle.tr),
      icon: const Icon(Icons.bug_report_outlined),
      child: RefreshIndicator(
        onRefresh: () {
          return Future.delayed(const Duration(milliseconds: 300), () {
            controller.loadLogFileList();
          });
        },
        child: Obx(
          () => ConditionWidget(
            condition: !controller.init.value,
            visible: const Loading(),
            invisible: ConditionWidget(
              condition: controller.logs.isEmpty,
              visible: Stack(
                children: [
                  ListView(),
                  EmptyContent(),
                ],
              ),
              invisible: ListView.builder(
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
                          var content = await file
                              .openRead()
                              .transform(
                                  const Utf8Decoder(allowMalformed: true))
                              .join();
                          final page = LogDetailPage(
                            fileName: file.fileName,
                            content: content,
                          );
                          if (controller.appConfig.isSmallScreen) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => page,
                              ),
                            );
                          } else {
                            Get.dialog(
                              DynamicSizeWidget(
                                widthScale: 0.8,
                                maxWidth: double.infinity,
                                child: page,
                              ),
                            );
                          }
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
            ),
          ),
        ),
      ),
    );
  }
}
