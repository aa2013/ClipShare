import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/history/history_event.dart';
import 'package:clipshare/core/providers/device/device_provider.dart';
import 'package:clipshare/core/providers/device/local_device_info.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/consumer_wrapper.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/features/history/widgets/card/history_card_content.dart';
import 'package:clipshare/features/history/widgets/clipboard_source_chip.dart';
import 'package:clipshare/features/history/widgets/history_drawer_content.dart';
import 'package:clipshare/features/history/widgets/card/history_tag_row.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/widgets/base/condition_widget.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClipboardDetailDrawer extends ConsumerStatefulWidget {
  final History history;
  final bool modifyMode;

  const ClipboardDetailDrawer({
    super.key,
    required this.history,
    this.modifyMode = false,
  });

  @override
  ConsumerState<ClipboardDetailDrawer> createState() {
    return _ClipboardDetailDrawerState();
  }
}

class _ClipboardDetailDrawerState extends ConsumerState<ClipboardDetailDrawer> {
  bool modifyMode = false;
  final editController = TextEditingController();

  /// 展示态使用的历史记录快照。
  ///
  /// 抽屉 widget 实例由 push 时创建并缓存在 MultiDrawerController 栈中，
  /// 不会随 historiesProvider 刷新而重建，保存修改后需手动同步此快照，
  /// 否则 Content/sizeText 等仍渲染旧值。
  late History _history;

  Snowflake get idGenerator => ref.read(idProvider);

  BaseDeviceInfo get self => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  @override
  void initState() {
    super.initState();
    modifyMode = widget.modifyMode;
    _history = widget.history;
    editController.text = widget.history.content;
  }

  @override
  Widget build(BuildContext context) {
    final drawer = ref.watch(drawerProvider);
    final drawerWidth = drawer.width;
    final showFullPage = drawerWidth > defaultDrawerWidth;
    final fullPageWidth = MediaQuery.of(context).size.width * 0.9;
    return Card(
      color: context.currentTheme.cardTheme.color,
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
                          drawer.controller.popWithAnimation();
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
                    if (_history.isText)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Tooltip(
                          message: modifyMode
                              ? TranslationKey.done.tr
                              : TranslationKey.modifyContent.tr,
                          child: IconButton(
                            onPressed: () {
                              if (modifyMode) {
                                // todo
                                dialogManager.tips(
                                  context,
                                  text: TranslationKey.confirmModifyContent.tr,
                                  actions: DialogActions(
                                    confirm: DialogAction(
                                      onPressed: _confirmModify,
                                    ),
                                    cancel: const DialogAction(),
                                  ),
                                );
                              } else {
                                setState(() {
                                  modifyMode = true;
                                });
                              }
                            },
                            icon: Icon(
                              modifyMode ? Icons.check : Icons.edit_note,
                              color: modifyMode
                                  ? Colors.blueAccent
                                  : Colors.blueGrey,
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
                      drawer.controller.popWithAnimation();
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
                      history: _history,
                      onAdded: (appInfo) {
                        setState(() {});
                      },
                      onDeleted: () {
                        setState(() {});
                      },
                    ),
                  ),

                  ///来源设备
                  consumerWrapper(
                    (context, ref) => _buildDeviceChip(_history, context, ref),
                  ),
                  const SizedBox(width: 5),

                  ///持有标签
                  Expanded(
                    child: HistoryTagRow(hisId: _history.id),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.1),

            ///剪贴板内容
            Expanded(
              child: Align(
                alignment: AlignmentGeometry.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: ConditionWidget(
                    visible: modifyMode,
                    replacement: HistoryDrawerContentView(
                      history: _history,
                      filePathSelectable: true,
                    ),
                    child: SizedBox.expand(
                      child: TextField(
                        textAlignVertical: TextAlignVertical.top,
                        textAlign: TextAlign.left,
                        controller: editController,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
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
            ),
            const Divider(height: 0.1),

            ///底部操作栏
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                    message: showFullPage
                        ? TranslationKey.fold.tr
                        : TranslationKey.unfold.tr,
                    child: IconButton(
                      onPressed: () {
                        final drawer = ref.read(drawerProvider.notifier);
                        drawer.resetWidth(
                          showFullPage ? defaultDrawerWidth : fullPageWidth,
                        );
                      },
                      icon: Icon(
                        showFullPage
                            ? Icons.keyboard_double_arrow_right
                            : Icons.keyboard_double_arrow_left,
                      ),
                    ),
                  ),
                  Text(_history.timeStr),
                  Text(_history.sizeText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceChip(
    History history,
    BuildContext context,
    WidgetRef ref,
  ) {
    final deviceState = ref.watch(deviceProvider).requireValue;

    return RoundedChip(
      avatar: const Icon(Icons.devices_rounded),
      label: Text(
        deviceState.getName(history.devId),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  ///确认修改内容
  Future<void> _confirmModify() async {
    final history = _history.copyWith(
      content: editController.text,
      size: editController.text.length,
      updateTime: Value(DateTime.now().toString()),
    );
    final db = await ref.read(appDbProvider.future);
    final cnt = await db.historyDao.updateHistory(history);
    final success = cnt == 1;
    if (success) {
      setState(() {
        modifyMode = false;
        _history = history;
      });
      var opRecord = newOperationRecord(
        idGenerator,
        self,
        Module.history,
        OpMethod.update,
        history.id.toString(),
      );
      await db.operationRecordDao.addAndNotify(opRecord);
      if (!mounted) {
        return;
      }
      snackbar.success(context, TranslationKey.updateSuccess.tr);
      final histories = ref.read(historiesProvider.notifier);
      histories.addDelta(
        HistoryDeltaEvent(history: history, operation: OpMethod.update),
      );
    } else {
      if (!mounted) {
        return;
      }
      snackbar.success(context, TranslationKey.updateFailed.tr);
    }
  }
}
