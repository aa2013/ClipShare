import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/views/log_detail_page.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LogController extends GetxController {
  final logs = <File>[].obs;
  final init = false.obs;
  final appConfig = Get.find<ConfigService>();

  @override
  void onInit() {
    super.onInit();
    loadLogFileList();
  }

  @override
  void onClose() {
    final settingController = Get.find<SettingsController>();
    settingController.updater.value++;
  }

  void loadLogFileList() {
    final directory = Directory(appConfig.logsDirPath);
    logs.value = [];
    if (!directory.existsSync()) {
      init.value = true;
      return;
    }
    List<FileSystemEntity> entities = directory.listSync(recursive: false);
    for (var entity in entities) {
      if (entity is File) {
        logs.add(entity);
      }
    }
    logs.sort(((a, b) => b.fileName.compareTo(a.fileName)));
    init.value = true;
  }

  Future<void> gotoLogDetailPage(File file) async {
    var content = await file.openRead().transform(const Utf8Decoder(allowMalformed: true)).join();
    final page = LogDetailPage(
      file: file,
      content: content,
    );
    if (appConfig.isSmallScreen) {
      Navigator.push(
        Get.context!,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    } else {
      var w = MediaQuery.of(Get.context!).size.width;
      final homeController = Get.find<HomeController>();
      homeController.openEndDrawer(drawer: page, width: w * 0.8, closeBefore: false);
    }
  }
}
