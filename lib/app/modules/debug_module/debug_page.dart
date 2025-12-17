import 'dart:convert';
import 'dart:io';
import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/android_notification_listener_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare/app/widgets/file_browser.dart';
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
            Global.showTipsDialog(context: context, text: "text");
          },
          child: Text("tips dialog"),
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
        TextButton(
          onPressed: () {
            final dialog1 = Global.showLoadingDialog(context: context, loadingText: "1");
            final dialog2 = Global.showLoadingDialog(context: context, loadingText: "2");
            final dialog3 = Global.showLoadingDialog(context: context, loadingText: "3");
            final dialog4 = Global.showLoadingDialog(context: context, loadingText: "4");
            Future.delayed(const Duration(seconds: 2), () async {
              dialog1.close();
              await Future.delayed(const Duration(seconds: 2));
              dialog2.close();
              await Future.delayed(const Duration(seconds: 2));
              dialog3.close();
              await Future.delayed(const Duration(seconds: 2));
              dialog4.close();
            });
          },
          child: Text("Show Dialogs"),
        ),
        TextButton(
          onPressed: () {
            dbService.historyDao.delete(1843814268377853952).then((res) {
              print(res);
            });
          },
          child: Text("Get by Id"),
        ),
        TextButton(
          onPressed: () {
            Get.toNamed(Routes.DB_EDITOR);
          },
          child: Text("goto db editor page"),
        ),
        TextButton(
          onPressed: () async {
            var notifyId = await NotifyUtil.notify(content: "notify 1", key: "dev");
            await Future.delayed(2.s);
            NotifyUtil.cancel("dev", notifyId!);
          },
          child: Text("Test Cancel Notify"),
        ),
        TextButton(
          onPressed: () async {
            await NotifyUtil.notify(content: "notify 1", key: "dev");
            await NotifyUtil.notify(content: "notify 2", key: "dev");
            await NotifyUtil.notify(content: "notify 3", key: "dev");
            await Future.delayed(2.s);
            NotifyUtil.cancelAll("dev");
          },
          child: Text("Test All Notifies"),
        ),
        TextButton(
          onPressed: () async {
            await NotifyUtil.notify(content: "notify 1", key: "dev");
            await NotifyUtil.notify(content: "notify 2", key: "dev");
            await NotifyUtil.notify(content: "notify 3", key: "dev");
            await Future.delayed(2.s);
            NotifyUtil.cancelExcludeLast("dev");
          },
          child: Text("Test All Notifies Exclude Last"),
        ),
        TextButton(
          onPressed: () async {
            Log.writeAndroidLogToday();
          },
          child: Text("666"),
        ),
        Expanded(
          child: FileBrowser(
            onLoadFiles: (String path) => [
              FileItem(name: 'aa', isDirectory: true, fullPath: 'a'),
              FileItem(name: 'bb', isDirectory: true, fullPath: 'b'),
              FileItem(name: 'cc', isDirectory: true, fullPath: 'c'),
            ],
            shouldShowUpLevel: (String currentPath) => true,
            initialPath: '/',
          ),
        ),
      ],
    );
  }
}
