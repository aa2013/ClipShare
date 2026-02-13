import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/widgets/clipboard_source_chip.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/modules/views/modify_history_content_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/clip_content_view.dart';
import 'package:clipshare/app/widgets/clip_tag_row_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';

class ClipDetailDialog extends StatefulWidget {
  final ClipData clip;
  final VoidCallback onUpdate;
  final BuildContext dlgContext;
  final void Function(ClipData item) onRemoveClicked;

  const ClipDetailDialog({
    required this.clip,
    required this.onUpdate,
    required this.onRemoveClicked,
    required this.dlgContext,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDetailDialogState();
  }
}

class ClipDetailDialogState extends State<ClipDetailDialog> {
  String get tag => "ClipDetailDialog";

  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final dbService = Get.find<DbService>();
  final historyController = Get.find<HistoryController>();
  final searchController = Get.find<search_module.SearchController>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 500),
      padding: const EdgeInsets.only(bottom: 30),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 7, top: 7, bottom: 7),
                  child: Text(
                    TranslationKey.clipboard.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        widget.onRemoveClicked(widget.clip);
                      },
                      tooltip: TranslationKey.deleteRecord.tr,
                    ),
                    IconButton(
                      icon: Icon(
                        widget.clip.data.top ? Icons.push_pin : Icons.push_pin_outlined,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        var id = widget.clip.data.id;
                        //置顶取反
                        var isTop = !widget.clip.data.top;
                        widget.clip.data.top = isTop;

                        dbService.historyDao.setTop(id, isTop).then((v) {
                          if (v == null || v <= 0) return;
                          var opRecord = OperationRecord.fromSimple(
                            Module.historyTop,
                            OpMethod.update,
                            id,
                          );
                          widget.onUpdate();
                          setState(() {});
                          dbService.opRecordDao.addAndNotify(opRecord);
                        });
                      },
                      tooltip: widget.clip.data.top ? TranslationKey.cancelTopUp.tr : TranslationKey.topUp.tr,
                    ),
                    Visibility(
                      visible: widget.clip.isImage || widget.clip.isText,
                      child: IconButton(
                        icon: appConfig.innerCopy
                            ? const Icon(
                                Icons.check,
                                color: Colors.blueGrey,
                              )
                            : const Icon(
                                Icons.copy,
                                color: Colors.blueGrey,
                              ),
                        onPressed: () {
                          appConfig.innerCopy = true;
                          setState(() {});
                          // 创建一个延迟0.5秒执行一次的定时器
                          Future.delayed(500.ms, () {
                            setState(() {});
                          });
                          var type = ClipboardContentType.parse(widget.clip.data.type);
                          clipboardManager.copy(type, widget.clip.data.content);
                        },
                        tooltip: TranslationKey.copyContent.tr,
                      ),
                    ),
                    Visibility(
                      visible: widget.clip.isText,
                      child: IconButton(
                        icon: const Icon(Icons.grain, color: Colors.blueGrey),
                        onPressed: () {
                          //关闭底部弹窗
                          Get.back();
                          final home = Get.find<HomeController>();
                          home.showSegmentWordsView(context, widget.clip.data.content);
                        },
                        tooltip: TranslationKey.segmentWords.tr,
                      ),
                    ),
                    Visibility(
                      visible: !widget.clip.isFile,
                      child: IconButton(
                        icon: const Icon(
                          Icons.sync,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          dbService.opRecordDao.resyncData(widget.clip.data.id);
                        },
                        tooltip: widget.clip.data.top ? TranslationKey.resyncRecord.tr : TranslationKey.syncRecord.tr,
                      ),
                    ),
                    Visibility(
                      visible: widget.clip.isText,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          Get.off(
                            () => ModifyHistoryContentPage(
                              data: widget.clip.data,
                              onDone: (bool didUpdate, String? newData) {
                                if (newData == null || !didUpdate) return;
                                widget.clip.data.content = newData;
                                widget.clip.data.updateTime = DateTime.now().toString();
                                dbService.historyDao.updateHistory(widget.clip.data).then((res) {
                                  final success = res == 1;
                                  if (success) {
                                    var opRecord = OperationRecord.fromSimple(
                                      Module.history,
                                      OpMethod.update,
                                      widget.clip.data.id.toString(),
                                    );
                                    dbService.opRecordDao.addAndNotify(opRecord);
                                    Global.showSnackBarSuc(text: TranslationKey.updateSuccess.tr, context: Get.context!);
                                    whereFunc(History item) => item.id == widget.clip.data.id;
                                    callbackFunc(History item) => item.content = newData;
                                    historyController.updateData(whereFunc, callbackFunc);
                                    searchController.updateData(whereFunc, callbackFunc);
                                  } else {
                                    Global.showSnackBarSuc(text: TranslationKey.updateFailed.tr, context: Get.context!);
                                  }
                                });
                              },
                            ),
                          );
                        },
                        tooltip: TranslationKey.modifyContent.tr,
                      ),
                    ),
                    Visibility(
                      visible: widget.clip.isFile,
                      child: IconButton(
                        icon: const Icon(
                          Icons.file_open,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () async {
                          final file = File(widget.clip.data.content);
                          await OpenFile.open(
                            file.normalizePath,
                          );
                        },
                        tooltip: TranslationKey.openFile.tr,
                      ),
                    ),
                    Visibility(
                      visible: widget.clip.isFile,
                      child: IconButton(
                        icon: const Icon(
                          Icons.folder,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () async {
                          final file = File(widget.clip.data.content);
                          file.openPath();
                        },
                        tooltip: TranslationKey.openFileFolder.tr,
                      ),
                    ),
                    Visibility(
                      visible: widget.clip.isFile,
                      child: IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          Share.shareXFiles(
                            [XFile(widget.clip.data.content)],
                            text: TranslationKey.shareFile.tr,
                          );
                        },
                        tooltip: TranslationKey.shareFile.tr,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// 标签栏
            Row(
              children: [
                //剪贴板来源
                ClipboardSourceChip(
                  clip: widget.clip,
                  onAdded: (appInfo) {
                    setState(() {});
                  },
                  onDeleted: () {
                    setState(() {});
                  },
                ),
                Expanded(
                  child: ClipTagRowView(
                    hisId: widget.clip.data.id,
                    showAddIcon: true,
                  ),
                ),
              ],
            ),

            ///剪贴板内容部分
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              margin: const EdgeInsets.only(top: 10),
              child: ClipContentView(
                clipData: widget.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
