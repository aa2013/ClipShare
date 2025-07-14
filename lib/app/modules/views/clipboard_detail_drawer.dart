import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/clip_content_view.dart';
import 'package:clipshare/app/widgets/clip_tag_row_view.dart';
import 'package:clipshare/app/widgets/clipboard_source_chip.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClipboardDetailDrawer extends StatefulWidget {
  final ClipData clipData;
  final bool modifyMode;

  const ClipboardDetailDrawer({
    super.key,
    required this.clipData,
    this.modifyMode = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _ClipboardDetailDrawerState();
  }
}

class _ClipboardDetailDrawerState extends State<ClipboardDetailDrawer> {
  bool modifyMode = false;
  final editController = TextEditingController();
  final dbService = Get.find<DbService>();
  final historyController = Get.find<HistoryController>();
  final searchController = Get.find<search_module.SearchController>();

  @override
  void initState() {
    super.initState();
    modifyMode = widget.modifyMode;
    editController.text = widget.clipData.data.content;
  }

  @override
  Widget build(BuildContext context) {
    final homeCtl = Get.find<HomeController>();
    final devService = Get.find<DeviceService>();
    final showFullPage = homeCtl.drawerWidth != null && homeCtl.drawerWidth! > 400;
    final fullPageWidth = MediaQuery.of(context).size.width * 0.9;
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: TranslationKey.fold.tr,
                      child: IconButton(
                        onPressed: () {
                          homeCtl.closeEndDrawer();
                        },
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        TranslationKey.clipboardContent.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (widget.clipData.isText)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Tooltip(
                          message: modifyMode ? TranslationKey.done.tr : TranslationKey.modifyContent.tr,
                          child: IconButton(
                            onPressed: () {
                              if (modifyMode) {
                                Global.showTipsDialog(
                                  context: context,
                                  text: TranslationKey.confirmModifyContent.tr,
                                  showCancel: true,
                                  onOk: () {
                                    widget.clipData.data.content = editController.text;
                                    widget.clipData.data.updateTime = DateTime.now().toString();
                                    dbService.historyDao.updateHistory(widget.clipData.data).then((res) {
                                      final success = res == 1;
                                      if (success) {
                                        setState(() {
                                          modifyMode = false;
                                        });
                                        var opRecord = OperationRecord.fromSimple(
                                          Module.history,
                                          OpMethod.update,
                                          widget.clipData.data.id.toString(),
                                        );
                                        dbService.opRecordDao.addAndNotify(opRecord);
                                        Global.showSnackBarSuc(text: TranslationKey.updateSuccess.tr, context: context);
                                        whereFunc(History item) => item.id == widget.clipData.data.id;
                                        callbackFunc(History item) => item.content = editController.text;
                                        historyController.updateData(whereFunc, callbackFunc);
                                        searchController.updateData(whereFunc, callbackFunc);
                                      } else {
                                        Global.showSnackBarSuc(text: TranslationKey.updateFailed.tr, context: context);
                                      }
                                    });
                                  },
                                );
                              } else {
                                setState(() {
                                  modifyMode = true;
                                });
                              }
                            },
                            icon: Icon(
                              modifyMode ? Icons.check : Icons.edit_note,
                              color: modifyMode ? Colors.blueAccent : Colors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Tooltip(
                  message: TranslationKey.close.tr,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      homeCtl.closeEndDrawer();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),

            ///标签栏
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: ClipboardSourceChip(
                      clip: widget.clipData,
                      onAdded: (appInfo) {
                        setState(() {});
                      },
                      onDeleted: () {
                        setState(() {});
                      },
                    ),
                  ),

                  ///来源设备
                  Obx(
                    () => RoundedChip(
                      avatar: const Icon(Icons.devices_rounded),
                      label: Text(
                        devService.getName(widget.clipData.data.devId),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  ///持有标签
                  Expanded(
                    child: ClipTagRowView(
                      hisId: widget.clipData.data.id,
                      clipBgColor: const Color(0x1a000000),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.1),

            ///剪贴板内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: ConditionWidget(
                  visible: modifyMode,
                  replacement: ClipContentView(
                    clipData: widget.clipData,
                  ),
                  child: SizedBox.expand(
                    child: TextField(
                      textAlignVertical: TextAlignVertical.top,
                      textAlign: TextAlign.left,
                      controller: editController,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1.5),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      expands: true,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 0.1),

            ///底部操作栏
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                    message: showFullPage ? TranslationKey.fold.tr : TranslationKey.unfold.tr,
                    child: IconButton(
                      onPressed: () {
                        homeCtl.openEndDrawer(
                          drawer: ClipboardDetailDrawer(clipData: widget.clipData),
                          width: showFullPage ? 400 : fullPageWidth,
                        );
                      },
                      icon: Icon(
                        showFullPage ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                      ),
                    ),
                  ),
                  Text(widget.clipData.timeStr),
                  Text(widget.clipData.sizeText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
