import 'dart:io';

import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DebugPage extends GetView<DebugController> {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final pageTag = "DebugPage";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            for (var value in List.generate(100, (i) => i)) {
              await Future.delayed(const Duration(milliseconds: 50));
              Clipboard.setData(ClipboardData(text: value.toString()));
            }
          },
          child: Text("Copy 100 items"),
        ),
        TextButton(
          onPressed: () {
            Global.showDownloadingDialog(
              context: context,
              url: "url",
              filePath: "",
              content: Text("...."),
              onFinished: (bool success) {},
            );
          },
          child: Text("show download dialog"),
        ),
        TextButton(
          onPressed: () async {
            OpenFile.open("pubspec.lock");
            // Process.run("explorer /select,\"pubspec.lock\"", []);
          },
          child: Text("open file path"),
        ),
      ],
    );
  }
}
