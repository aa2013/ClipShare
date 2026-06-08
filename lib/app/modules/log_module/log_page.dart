import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/log_module/log_list_view.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LogPage extends GetView<LogController> {
  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final showAppBar = appConfig.isSmallScreen;
    final content = LogListView(
      controller: controller,
      showHeader: !showAppBar,
    );
    if (showAppBar) {
      final appBar = AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TranslationKey.logPageAppBarTitle.tr),
            LogClearButton(controller: controller),
          ],
        ),
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
