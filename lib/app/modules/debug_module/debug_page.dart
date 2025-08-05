import 'dart:convert';
import 'dart:io';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/white_black_rule.dart';
import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/modules/views/white_black_list_page.dart';
import 'package:clipshare/app/services/android_notification_listener_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
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
            final byteData = await rootBundle.load(Constants.emptyPngPath);
            final bytes = byteData.buffer.asUint8List();
            print(base64.encode(bytes));
          },
          child: Text("GetEmptyContentPngBytes"),
        ),
        if (Platform.isAndroid)
          Obx(
            () => Switch(
              value: controller.ntfListening.value,
              onChanged: (checked) {
                controller.ntfListening.value = checked;
                final notificationListenerService = Get.find<AndroidNotificationListenerService>();
                if (checked) {
                  notificationListenerService.startListening();
                } else {
                  notificationListenerService.stopListening();
                }
              },
            ),
          ),
        if (Platform.isAndroid)
          TextButton(
            onPressed: () async {
              final result = await NotificationListenerService.isPermissionGranted();
              print(result);
              NotificationListenerService.requestPermission();
            },
            child: const Text("request data"),
          ),
        Expanded(
          child: Obx(
            () => WhiteBlackListPage(
              title: TranslationKey.blacklistRules.tr,
              showMode: WhiteBlackMode.all,
              enabled: controller.enableBlacklist.value,
              blacklist: appConfig.contentBlackList,
              onModeChanged: (mode, enabled) {
                controller.enableBlacklist.value = enabled;
              },
              onDone: (_, Map<WhiteBlackMode, List<FilterRule>> data) {},
            ),
          ),
        ),
      ],
    );
  }
}
