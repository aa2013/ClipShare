import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/features/file_transfer/providers/file_history_provider.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_history_card.dart';
import 'package:clipshare/features/history/providers/history_delete_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文件历史列表：展示历史发送/接收的文件记录，支持长按多选批量删除
class FileHistoryList extends ConsumerStatefulWidget {
  /// 多选模式切换回调，供外部隐藏/显示添加入口
  final ValueChanged<bool>? onSelectModeChanged;

  const FileHistoryList({
    super.key,
    this.onSelectModeChanged,
  });

  @override
  ConsumerState<FileHistoryList> createState() => _FileHistoryListState();
}

class _FileHistoryListState extends ConsumerState<FileHistoryList> {
  static const _selectedChipColor = Color(0xffc3e8ff);

  var _selectMode = false;
  final _selected = <int, History>{};

  String get _selfDevId => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo.guid;

  bool get _allSelected {
    final list = ref.read(fileHistoryProvider).value ?? const [];
    return list.isNotEmpty && _selected.length == list.length;
  }

  @override
  Widget build(BuildContext context) {
    final histories = ref.watch(fileHistoryProvider);
    final totalCount = histories.value?.length ?? 0;
    return CustomKeyboardListener(
      shortcuts: [
        if (_selectMode)
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.escape},
            onTrigger: exitSelectionMode,
          ),
      ],
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(fileHistoryProvider),
            child: histories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: EmptyContent(description: TranslationKey.failed.tr),
              ),
              data: (list) => Visibility(
                visible: list.isNotEmpty,
                //空列表放置可滚动容器以下拉刷新
                replacement: Stack(
                  children: [
                    const Center(child: EmptyContent()),
                    ListView(),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(5),
                  itemCount: list.length,
                  itemBuilder: (ctx, idx) {
                    final history = list[idx];
                    final id = history.id;
                    return TransferHistoryCard(
                      history: history,
                      isSent: history.devId == _selfDevId,
                      selectMode: _selectMode,
                      selected: _selected.containsKey(id),
                      onToggleSelected: () => _toggleSelected(history),
                      onLongPress: () => _enterSelectionMode(history),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_selectMode)
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  //选中计数
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedChipColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(right: 10),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${_selected.length} / $totalCount',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).brightness == .dark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  //取消选择
                  Tooltip(
                    message: TranslationKey.deselect.tr,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: FloatingActionButton(
                        onPressed: exitSelectionMode,
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  //全选/取消全选
                  Tooltip(
                    message: _allSelected ? TranslationKey.cancelSelectAll.tr : TranslationKey.selectAll.tr,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: FloatingActionButton(
                        onPressed: _toggleSelectAll,
                        child: Icon(_allSelected ? Icons.deselect : Icons.checklist),
                      ),
                    ),
                  ),
                  //删除
                  if (_selected.isNotEmpty)
                    Tooltip(
                      message: TranslationKey.delete.tr,
                      child: FloatingActionButton(
                        onPressed: _showDeleteDialog,
                        child: const Icon(Icons.delete_forever),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 进入多选模式并选中长按的记录
  void _enterSelectionMode(History history) {
    setState(() {
      _selectMode = true;
      _selected[history.id] = history;
    });
    widget.onSelectModeChanged?.call(true);
  }

  /// 切换单条记录选中态，全部取消时退出多选
  void _toggleSelected(History history) {
    setState(() {
      if (_selected.remove(history.id) == null) {
        _selected[history.id] = history;
      } else if (_selected.isEmpty) {
        _selectMode = false;
        widget.onSelectModeChanged?.call(false);
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll() {
    final list = ref.read(fileHistoryProvider).value;
    if (list == null || list.isEmpty) {
      return;
    }
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        for (final item in list) {
          _selected[item.id] = item;
        }
      }
    });
  }

  /// 退出多选模式并清空选中
  void exitSelectionMode() {
    if (!_selectMode) {
      return;
    }
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
    widget.onSelectModeChanged?.call(false);
  }

  /// 打开批量删除确认框：仅删除记录 / 连带删除接收文件的本地副本
  Future<void> _showDeleteDialog() async {
    await dialogManager.tips(
      context,
      text: TranslationKey.syncingFilePageDeleteSelectedDialogContent.trParams({'length': _selected.length.toString()}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          text: TranslationKey.onlyDeleteRecordsText.tr,
          onPressed: () => _deleteSelected(false),
        ),
        neutral: DialogAction(
          text: TranslationKey.deleteWithFiles.tr,
          onPressed: () => _deleteSelected(true),
        ),
      ),
    );
  }

  /// 批量删除选中记录，统一用一个加载弹窗。
  /// [deleteFile] 为 true 时仅连带删除接收文件的本地副本，本机发送的源文件保留。
  Future<void> _deleteSelected(bool deleteFile) async {
    final selfDevId = _selfDevId;
    final items = _selected.values.toList();
    final loadingDialog = dialogManager.loading(
      context,
      loadingText: TranslationKey.deleting.tr,
    );
    final deleteNotifier = ref.read(historyDeleteProvider.notifier);
    var hasError = false;
    for (final item in items) {
      final success = await deleteNotifier.delete(
        item,
        deleteFile: deleteFile && item.devId != selfDevId,
      );
      if (!success) {
        hasError = true;
      }
    }
    await loadingDialog.close();
    if (!mounted) {
      return;
    }
    if (hasError) {
      snackbar.warn(context, TranslationKey.partialDeletionFailed.tr);
    } else {
      snackbar.success(context, TranslationKey.deleteCompleted.tr);
    }
    exitSelectionMode();
  }
}
