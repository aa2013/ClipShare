import 'package:clipshare/app/modules/statistics_module/statistics_controller.dart';
import 'package:clipshare/app/modules/statistics_module/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsStatisticsPage extends StatelessWidget {
  final bool embedded;

  const SettingsStatisticsPage({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StatisticsController>()) {
      Get.put(StatisticsController());
    }
    return StatisticsPage();
  }
}
