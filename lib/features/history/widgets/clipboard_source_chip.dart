import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:flutter/material.dart';

import 'app_icon.dart';

class ClipboardSourceChip extends StatelessWidget {
  final History history;
  final Function(AppInfo appInfo) onAdded;
  final Function() onDeleted;

  const ClipboardSourceChip({
    super.key,
    required this.history,
    required this.onAdded,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (history.source == null) {
      return RoundedChip(
        onPressed: () {
          // final page = AppSelectionPage(
          //   limit: 1,
          //   loadDeviceName: devService.getName,
          //   loadAppInfos: () {
          //     final list = sourceService.appInfos
          //         .where((item) => item.devId == appConfig.device.guid)
          //         .map((item) => LocalAppInfo.fromAppInfo(item, false))
          //         .toList();
          //     return Future<List<LocalAppInfo>>.value(list);
          //   },
          //   onSelectedDone: (selected) async {
          //     final appInfo = selected[0];
          //     final id = history.id;
          //     final success = await dbService.historyDao
          //         .updateHistorySourceAndNotify(id, appInfo.appId);
          //     if (success) {
          //       historyController.updateData(
          //         (history) => history.id == id,
          //         (history) => history.source = appInfo.appId,
          //         false,
          //       );
          //       Global.showSnackBarSuc(
          //           context: context, text: TranslationKey.updateSuccess.tr);
          //       onAdded(appInfo);
          //     } else {
          //       Global.showSnackBarErr(
          //           context: context, text: TranslationKey.updateFailed.tr);
          //     }
          //   },
          // );
          // if (context.isCompactScreen) {
          //   Get.to(page);
          // } else {
          //   Global.showDialog(context, DynamicSizeWidget(child: page));
          // }
        },
        avatar: const Icon(Icons.add),
        label: Text(
          TranslationKey.source.tr,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
    return AppIcon(
      appId: history.source!,
      onDeleteClicked: () {
        // Global.showTipsDialog(
        //   context: context,
        //   text: TranslationKey.clearSourceConfirmText.tr,
        //   onOk: () async {
        //     final id = history.id;
        //     final success =
        //         await dbService.historyDao.clearHistorySourceAndNotify(id);
        //     if (success) {
        //       historyController.updateData(
        //         (history) => history.id == id,
        //         (history) => history.source = null,
        //         false,
        //       );
        //       //移除未使用的剪贴板来源信息
        //       await sourceService.removeNotUsed();
        //       Global.showSnackBarSuc(
        //           context: context, text: TranslationKey.clearSuccess.tr);
        //       onDeleted();
        //     } else {
        //       Global.showSnackBarErr(
        //           context: context, text: TranslationKey.clearFailed.tr);
        //     }
        //   },
        //   showCancel: true,
        // );
      },
    );
  }
}
