import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClipboardSourceChip extends StatelessWidget {
  final ClipData clip;
  final Function(AppInfo appInfo) onAdded;
  final Function() onDeleted;
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final appConfig = Get.find<ConfigService>();
  final historyController = Get.find<HistoryController>();
  final sourceService = Get.find<ClipboardSourceService>();

  ClipboardSourceChip({
    super.key,
    required this.clip,
    required this.onAdded,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (clip.data.source == null) {
      return RoundedChip(
        onPressed: () {
          final page = AppSelectionPage(
            limit: 1,
            loadDeviceName: devService.getName,
            loadAppInfos: () {
              final list = sourceService.appInfos
                  .where((item)=>item.devId==appConfig.device.guid)
                  .map((item) => LocalAppInfo.fromAppInfo(item, false))
                  .toList();
              return Future<List<LocalAppInfo>>.value(list);
            },
            onSelectedDone: (selected) async {
              final appInfo = selected[0];
              final id = clip.data.id;
              final success = await dbService.historyDao.updateHistorySourceAndNotify(id, appInfo.appId);
              if (success) {
                historyController.updateData(
                  (history) => history.id == id,
                  (history) => history.source = appInfo.appId,
                  false,
                );
                Global.showSnackBarSuc(context: context, text: TranslationKey.updateSuccess.tr);
                onAdded(appInfo);
              } else {
                Global.showSnackBarErr(context: context, text: TranslationKey.updateFailed.tr);
              }
            },
          );
          if(appConfig.isSmallScreen){
            Get.to(page);
          }else{
            Get.dialog(DynamicSizeWidget(child: page));
          }
        },
        avatar: const Icon(Icons.add),
        label: Text(
          TranslationKey.source.tr,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
    return AppIcon(
      appId: clip.data.source!,
      onDeleteClicked: () {
        Global.showTipsDialog(
          context: context,
          text: TranslationKey.clearSourceConfirmText.tr,
          onOk: () async {
            final id = clip.data.id;
            final success = await dbService.historyDao.clearHistorySourceAndNotify(id);
            if (success) {
              historyController.updateData(
                (history) => history.id == id,
                (history) => history.source = null,
                false,
              );
              //移除未使用的剪贴板来源信息
              await sourceService.removeNotUsed();
              Global.showSnackBarSuc(context: context, text: TranslationKey.clearSuccess.tr);
              onDeleted();
            } else {
              Global.showSnackBarErr(context: context, text: TranslationKey.clearFailed.tr);
            }
          },
          showCancel: true,
        );
      },
    );
  }
}
