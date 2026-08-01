import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/update_log_module/update_log_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UpdateLogPage extends GetView<UpdateLogController> {
  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final showAppBar = appConfig.isSmallScreen;
    final String platform;
    if (Platform.isIOS) {
      platform = "IOS";
    } else if (Platform.isMacOS) {
      platform = "MacOS";
    } else {
      platform = Platform.operatingSystem.upperFirst;
    }
    final content = FutureBuilder(
      future: rootBundle.loadString("assets/md/updateLogs-$platform.md"),
      builder: (context, v) {
        return Markdown(
          data: v.data ?? TranslationKey.failedToReadUpdateLog.tr,
          selectable: true,
          onSelectionChanged:
              (
                String? text,
                TextSelection selection,
                SelectionChangedCause? cause,
              ) {},
        );
      },
    );
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Text(TranslationKey.updateLogPageAppBarTitle.tr),
              )
            : null,
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
