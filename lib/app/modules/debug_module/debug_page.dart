import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
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
          onPressed: () async {
            final path = "${Constants.androidDownloadPath}/app-arm64-v8a-release.apk";
            File(path).openPath();
            final result = await OpenFile.open(path);
            print("result ${result.type.name}.${result.message}");
            // Process.run("explorer /select,\"pubspec.lock\"", []);
          },
          child: Text("open file path"),
        ),
        Expanded(
          child: AppSelectionPage(
            distinguishSystemApps: true,
            loadAppInfos: () {
              final sourceService = Get.find<ClipboardSourceService>();
              final result = sourceService.appInfos.map((item) => LocalAppInfo.fromAppInfo(item, Random().nextInt(10) > 5)).toList(growable: false);
              return Future.value(result);
            },
            onSelectedDone: (list) {
              print("onSelectedDone: ${list.length}");
            },
          ),
        ),
      ],
    );
  }
}
