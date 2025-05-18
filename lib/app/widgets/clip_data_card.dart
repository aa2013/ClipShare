import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/views/clipboard_detail_drawer.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/modules/views/tag_edit_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/clip_simple_data_extra_info.dart';
import 'package:clipshare/app/widgets/clip_simple_data_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final void Function()? onDoubleTap;
  final void Function() onUpdate;
  final void Function(ClipData item) onRemoveClicked;
  final bool routeToSearchOnClickChip;
  final bool imageMode;
  final bool selectMode;
  final bool selected;

  const ClipDataCard({
    required this.clip,
    required this.onUpdate,
    required this.onRemoveClicked,
    super.key,
    this.routeToSearchOnClickChip = false,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.imageMode = false,
    this.selectMode = false,
    this.selected = false,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  var _readyDoubleClick = false;
  static const _borderWidth = 2.0;
  static const _borderRadius = 12.0;
  bool _selected = false;

  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.selected;
    final content = Card(
      elevation: 0,
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: () {
          if (widget.selectMode) {
            setState(() {
              _selected = !_selected;
            });
            widget.onTap?.call();
            return;
          }
          if (PlatformExt.isDesktop) {
            widget.onTap?.call();
            return;
          }
          if (widget.onDoubleTap == null) {
            //未设置双击，直接执行单击
            widget.onTap?.call();
          } else {
            //设置了双击，且已经点击过一次，执行双击逻辑
            if (_readyDoubleClick) {
              widget.onDoubleTap!.call();
              //双击结束，恢复状态
              _readyDoubleClick = false;
            } else {
              _readyDoubleClick = true;
              //设置了双击，但仅点击了一次，延迟一段时间
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_readyDoubleClick) {
                  //指定时间后仍然没有进行第二次点击，进行单击逻辑
                  widget.onTap?.call();
                }
                //指定时间后无论是否双击，恢复状态
                _readyDoubleClick = false;
              });
            }
          }
        },
        onLongPress: () {
          widget.onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Container(
          margin: widget.selectMode && _selected ? null : const EdgeInsets.all(_borderWidth),
          decoration: widget.selectMode && _selected
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: _borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(_borderRadius),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ClipSimpleDataHeader(
                    clip: widget.clip,
                    routeToSearchOnClickChip: widget.routeToSearchOnClickChip,
                  ),
                ),
                widget.imageMode
                    ? IntrinsicHeight(
                        child: GestureDetector(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(
                                widget.clip.data.content,
                              ),
                              fit: BoxFit.fitWidth,
                              width: 200,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PreviewPage(
                                  clip: widget.clip,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: ClipSimpleDataContent(
                            clip: widget.clip,
                          ),
                        ),
                      ),
                ClipSimpleDataExtraInfo(clip: widget.clip),
              ],
            ),
          ),
        ),
      ),
    );
    return GestureDetector(
      child: content,
      onSecondaryTapDown: (details) {
        showMenu(details.globalPosition - const Offset(0, 70));
      },
    );
  }

  ///右键菜单
  void showMenu(Offset? position) {
    final menu = ContextMenu(
      entries: [
        MenuItem(
          label: widget.clip.data.top ? TranslationKey.cancelTopUp.tr : TranslationKey.topUp.tr,
          icon: widget.clip.data.top ? Icons.push_pin : Icons.push_pin_outlined,
          onSelected: () {
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
        ),
        if (!widget.clip.isFile)
          MenuItem(
            label: TranslationKey.copyContent.tr,
            icon: Icons.copy,
            onSelected: () {
              appConfig.innerCopy = true;
              var type = ClipboardContentType.parse(widget.clip.data.type);
              clipboardManager.copy(type, widget.clip.data.content);
              Global.showSnackBarSuc(text: TranslationKey.copySuccess.tr, context: context);
            },
          ),
        if (!widget.clip.isFile)
          MenuItem(
            label: widget.clip.data.sync ? TranslationKey.resyncRecord.tr : TranslationKey.syncRecord.tr,
            icon: Icons.sync,
            onSelected: () {
              var opRecord = OperationRecord.fromSimple(
                Module.history,
                OpMethod.add,
                widget.clip.data.id.toString(),
              );
              dbService.opRecordDao.addAndNotify(opRecord);
            },
          ),
        if (widget.clip.isFile)
          MenuItem(
            label: TranslationKey.openFile.tr,
            icon: Icons.file_open,
            onSelected: () async {
              final file = File(widget.clip.data.content);
              await OpenFile.open(file.normalizePath);
            },
          ),
        if (widget.clip.isFile)
          MenuItem(
            label: TranslationKey.openFileFolder.tr,
            icon: Icons.folder,
            onSelected: () async {
              final file = File(widget.clip.data.content);
              await OpenFile.open(
                file.parent.normalizePath,
              );
            },
          ),
        MenuItem(
          label: TranslationKey.tagsManagement.tr,
          icon: Icons.tag,
          onSelected: () {
            TagEditPage.goto(widget.clip.data.id);
          },
        ),
        MenuItem(
          label: TranslationKey.modifyContent.tr,
          icon: Icons.edit_note,
          onSelected: () {
            final homCtl = Get.find<HomeController>();
            homCtl.openEndDrawer(
              drawer: ClipboardDetailDrawer(
                clipData: widget.clip,
                modifyMode: true,
              ),
            );
          },
        ),
        MenuItem(
          label: TranslationKey.delete.tr,
          icon: Icons.delete,
          onSelected: () {
            widget.onRemoveClicked(widget.clip);
          },
        ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }

  ///删除数据
  Future<bool> removeData() async {
    var id = widget.clip.data.id;
    //删除tag
    await dbService.historyTagDao.removeAllByHisId(id);
    //删除历史
    return dbService.historyDao.delete(id).then((v) {
      if (v == null || v <= 0) return false;
      //添加删除记录
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.delete,
        id,
      );
      dbService.opRecordDao.addAndNotify(opRecord);
      return true;
    });
  }
}
