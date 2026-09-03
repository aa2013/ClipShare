import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/extensions/history_data_extension.dart';
import 'package:clipshare/core/history/history_event.dart';
import 'package:clipshare/core/providers/device/local_device_info.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/core/providers/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/features/history/enums/history_card_menu_action.dart';
import 'package:clipshare/features/history/pages/clipboard_detail_drawer.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/features/history/widgets/history_multi_selection_controller.dart';
import 'package:clipshare/features/history/widgets/history_multi_selection_fab.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/features/segment_words/pages/segment_words_page.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/src/expandable_fab.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/src/widgets/masonry_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file_plus/open_file_plus.dart';

import 'card/history_card.dart';

class ClipListView extends ConsumerStatefulWidget {
  final List<History> list;
  final bool imageMode;
  final EdgeInsetsGeometry? padding;
  final RefreshCallback onRefresh;

  const ClipListView({
    super.key,
    required this.list,
    required this.onLoadMoreData,
    required this.onRefresh,
    this.onExport,
    this.imageMode = false,
    this.padding,
  });

  final Future<void> Function() onLoadMoreData;

  /// 导出入口，由 HistoryPage 下传；多选导出复用其确认弹窗、进度与分页逻辑。
  final Future Function(FutureOr<List<History>> Function(int lastId) loadDataFunc)? onExport;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ClipListViewState();
}

class _ClipListViewState extends ConsumerState<ClipListView> {
  static const tag = 'ClipListView';
  final scrollController = ScrollController();
  final alwaysScrollPhysics = const AlwaysScrollableScrollPhysics();
  final _selectionController = HistoryMultiSelectionController();
  var _showBackToTopButton = false;

  Snowflake get _idGenerator => ref.read(idProvider);

  BaseDeviceInfo get _self => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  bool get selectMode => _selectionController.enabled;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant ClipListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectionController.removeMissingItems(widget.list);
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  /// 滚动超过阈值时显示回到顶部按钮。
  void _scrollListener() {
    final show = scrollController.offset >= 300;
    if (show != _showBackToTopButton) {
      setState(() => _showBackToTopButton = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomKeyboardListener(
        shortcuts: [
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.escape},
            onTrigger: exitSelectionMode,
          ),
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.delete},
            onTrigger: showSelectedDeleteDialog,
          ),
        ],
        child: _buildBody(),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 多选扇形 FAB：取消选择、删除、合并复制、导出。
  Widget _buildFloatingActionButton() {
    return HistoryMultiSelectionFab(
      distance: 145,
      selectMode: selectMode,
      selectedCount: _selectionController.selectedCount,
      totalCount: widget.list.length,
      showBackToTopButton: _showBackToTopButton,
      onBackToTop: () async {
        await Future.delayed(100.ms);
        await scrollController.animateTo(
          0,
          duration: 500.ms,
          curve: Curves.easeInOut,
        );
      },
      actions: [
        HistoryMultiSelectionFabAction(
          onPressed: exitSelectionMode,
          tooltip: '${TranslationKey.deselect.tr} ($selectionExitShortcutLabel)',
          child: const Icon(MdiIcons.cancel),
        ),
        HistoryMultiSelectionFabAction(
          onPressed: showSelectedDeleteDialog,
          tooltip: '${TranslationKey.delete.tr} ($selectionDeleteShortcutLabel)',
          child: const Icon(Icons.delete_forever),
        ),
        HistoryMultiSelectionFabAction(
          onPressed: _selectionController.canMergeCopy ? _copyMergedContent : null,
          tooltip: TranslationKey.copyMergedContent.tr,
          child: const Icon(Icons.content_copy_rounded),
        ),
        HistoryMultiSelectionFabAction(
          onPressed: _selectionController.canMergeCopy && widget.onExport != null
                  ? _exportSelected
                  : null,
          tooltip: TranslationKey.output.tr,
          child: const Icon(MdiIcons.export),
        ),
      ],
    );
  }

  Widget _buildBody() {
    Widget list;
    if (widget.list.isEmpty) {
      list = Stack(
        children: [
          ListView(),
          const EmptyContent(),
        ],
      );
    } else {
      list = _buildList();
    }

    return PopScope(
      canPop: !selectMode,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (selectMode) {
          exitSelectionMode();
        }
      },
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: list,
      ),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isImageMode = widget.imageMode;
        final maxWidth = isImageMode ? 200.0 : 395;
        final preferenceSettings = ref.watch(preferenceSettingsProvider).requireValue;
        final showMoreItems = preferenceSettings.showMoreItemsInRow;
        final isCompactScreen = context.isCompactScreen;
        final showMore = (showMoreItems && !isCompactScreen) || isImageMode;
        final count = showMore ? max(2, constraints.maxWidth ~/ maxWidth) : 1;
        return Listener(
          child: MasonryGridView.count(
            crossAxisCount: count,
            mainAxisSpacing: 4,
            padding: widget.padding,
            shrinkWrap: true,
            itemCount: widget.list.length,
            controller: scrollController,
            physics: alwaysScrollPhysics,
            itemBuilder: (context, index) {
              if (isImageMode) {
                return _renderItem(index);
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  constraints: const BoxConstraints(
                    maxHeight: 150,
                    minHeight: 80,
                  ),
                  child: _renderItem(index),
                );
              }
            },
          ),
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              final pos = scrollController.position.pixels;
              final maxExtent = scrollController.position.maxScrollExtent;
              if (pos == maxExtent) {
                logger.debug(tag, 'Try loading more data at the bottom');
                unawaited(widget.onLoadMoreData());
              }
            }
          },
        );
      },
    );
  }

  Widget _renderItem(int i) {
    final history = widget.list[i];
    return HistoryCard(
      key: ValueKey(history.id),
      history: history,
      selected: _selectionController.contains(history),
      selectMode: selectMode,
      onTap: () => onCardTap(history),
      onLongPress: () => onCardLongPress(history),
      onToggleSelected: () => onCardToggleSelected(history),
      onMenuSelected: (action) => onCardMenuSelected(action, history),
    );
  }

  void onCardTap(History history) {
    if (selectMode) {
      toggleSelect(history);
      return;
    }
    final drawer = ref.read(drawerProvider);
    if (!context.isCompactScreen) {
      final drawerNotifier = ref.read(drawerProvider.notifier);
      drawer.controller.push(
        ClipboardDetailDrawer(history: history),
        () {
          drawerNotifier.resetWidth();
          return true;
        },
      );
    } else {
      //todo
      // showClipBottomSheet(data);
    }
  }

  void onCardLongPress(History history) {
    _enableSelectMode();
    _selectionController.toggleItem(history);
    setState(() {});
  }

  /// 多选模式下按目标项与已有选中项做区间补选。
  void onCardToggleSelected(History history) {
    _enableSelectMode();
    HapticFeedback.mediumImpact();
    _selectionController.selectRange(widget.list, history);
    setState(() {});
  }

  void toggleSelect(History history) {
    _selectionController.toggleItem(history);
    setState(() {});
  }

  /// 开启多选模式
  void _enableSelectMode() {
    if (_selectionController.enabled) {
      return;
    }
    _selectionController.enable();
    setState(() {});
  }

  /// 退出多选模式；快捷键和 FAB 共用该入口
  void exitSelectionMode() {
    if (!selectMode) {
      return;
    }
    setState(() => _selectionController.clearAndExit());
  }

  ///region menu selected

  void onCardMenuSelected(HistoryCardMenuAction action, History history){
    switch(action){
      case HistoryCardMenuAction.top:
        onTopMenuSelected(history);
        break;
      case HistoryCardMenuAction.segment:
        onSegmentMenuSelected(history);
        break;
      case HistoryCardMenuAction.copy:
        onCopyMenuSelected(history);
        break;
      case HistoryCardMenuAction.resync:
        onResyncMenuSelected(history);
        break;
      case HistoryCardMenuAction.openFile:
        onOpenFileMenuSelected(history);
        break;
      case HistoryCardMenuAction.openFileFolder:
        onOpenFileFolderMenuSelected(history);
        break;
      case HistoryCardMenuAction.tagManager:
        onTagManagerMenuSelected(history);
        break;
      case HistoryCardMenuAction.modify:
        onModifyMenuSelected(history);
        break;
      case HistoryCardMenuAction.delete:
        onDeleteMenuSelected(history);
        break;
    }
  }

  Future<void> onTopMenuSelected(History history) async {
    final db = await ref.read(appDbProvider.future);
    var id = history.id;
    //置顶取反
    var isTop = !history.top;
    final cnt = await db.historyDao.setTop(id, isTop);
    if (cnt == null || cnt <= 0) return;
    var opRecord = newOperationRecord(
      _idGenerator,
      _self,
      Module.historyTop,
      OpMethod.update,
      id,
    );
    await db.operationRecordDao.addAndNotify(opRecord);
    ref.read(historiesProvider.notifier).addDelta(
        HistoryDeltaEvent(
          history: history.copyWith(top: isTop),
          operation: OpMethod.update,
        ),
    );
  }

  Future<void> onSegmentMenuSelected(History history) async {
    // 先确保词典已安装、worker 已初始化，再叠加进入分词页
    final ready = await ensureJiebaSegmentReady(context, ref);
    if (!ready || !mounted) {
      return;
    }
    unawaited(
      context.pushNamed(
        AppRoutes.segmentWords.name,
        extra: SegmentWordsRouteArgs(text: history.content),
      ),
    );
  }

  void onCopyMenuSelected(History history){
    history.copyContent(context: context, showFeedback: true);
  }

  Future<void> onResyncMenuSelected(History history) async {
    final db = await ref.read(appDbProvider.future);
    await db.operationRecordDao.resyncData(history.id);
  }

  void onOpenFileMenuSelected(History history) {
    final file = File(history.content);
    OpenFile.open(file.normalizePath);
  }

  void onOpenFileFolderMenuSelected(History history) {
    final file = File(history.content);
    file.openPath();
  }

  void onTagManagerMenuSelected(History history){
    //todo
    // TagEditPage.goto(widget.history.id);
  }

  void onModifyMenuSelected(History history){
    final drawer = ref.read(drawerProvider);
    drawer.controller.push(
      ClipboardDetailDrawer(
        history: history,
        modifyMode: true,
      ),
      null,
    );
  }

  /// 删除单条历史
  /// [deleteFile] 连带删除本地文件
  /// [onlyDeleteLocal] 时不产生同步删除记录。
  Future<void> deleteItem(
    History history, {
    bool deleteFile = false,
    bool onlyDeleteLocal = false,
    bool showLoading = true,
  }) async {
    DialogController? loadingDialog;
    var deleteSuccess = false;
    try {
      if (showLoading) {
        loadingDialog = dialogManager.loading(
          context,
          loadingText: TranslationKey.deleting.tr,
        );
      }
      final db = await ref.read(appDbProvider.future);
      await db.historyDao.deleteByCascade(history.id);
      // 通知事件流，让列表移除该记录
      ref.read(historiesProvider.notifier)
          .addDelta(
            HistoryDeltaEvent(
              history: history,
              operation: OpMethod.delete,
            ),
          );
      if (!onlyDeleteLocal) {
        final opRecord = newOperationRecord(
          _idGenerator,
          _self,
          Module.history,
          OpMethod.delete,
          history.id,
        );
        await db.operationRecordDao.addAndNotify(opRecord);
      }
      if (deleteFile && (history.isImage || history.isFile)) {
        final file = File(history.content);
        if (await file.exists()) {
          await file.delete();
          //todo Android 相册媒体扫描通知待接入（当前分支无 AndroidChannelService）
        }
      }
      deleteSuccess = true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      if (!showLoading) {
        rethrow;
      }
      await loadingDialog?.close();
      loadingDialog = null;
      if (mounted) {
        snackbar.warn(context, TranslationKey.deletionFailed.tr);
      }
    } finally {
      await loadingDialog?.close();
      if (deleteSuccess && showLoading && mounted) {
        snackbar.success(context, TranslationKey.deleteSuccess.tr);
      }
    }
  }

  /// 打开单条删除确认框，可选择是否连带删除文件、是否仅本地删除。
  Future<void> onDeleteMenuSelected(History history) async {
    final onlyDeleteLocal = ValueNotifier(false);
    final canDeleteFile = history.isFile || history.isImage;
    await dialogManager.tips(
      context,
      title: TranslationKey.deleteTips.tr,
      text: TranslationKey.clipListDeleteRecordDialogContent.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () => deleteItem(history, onlyDeleteLocal: onlyDeleteLocal.value),
        ),
        neutral: canDeleteFile
            ? DialogAction(
                text: TranslationKey.deleteWithFiles.tr,
                onPressed: () => deleteItem(
                  history,
                  deleteFile: true,
                  onlyDeleteLocal: onlyDeleteLocal.value,
                ),
              )
            : null,
      ),
      customWidget: _buildOnlyLocalCheckbox(onlyDeleteLocal),
    );
  }

  ///endregion

  /// 打开多选删除确认弹窗；Delete 快捷键与删除 FAB 共用该入口。
  Future<void> showSelectedDeleteDialog() async {
    if (!_selectionController.enabled || _selectionController.selectedItems.isEmpty) {
      return;
    }
    final items = _selectionController.selectedItems.toList();
    final onlyDeleteLocal = ValueNotifier(false);
    final hasFile = items.any((h) => h.isFile);
    await dialogManager.tips(
      context,
      text: TranslationKey.multiDeleteAsk.trParams({'length': items.length.toString()}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () => _deleteSelectedItems(items, false, onlyDeleteLocal.value),
        ),
        neutral: hasFile
            ? DialogAction(
                text: TranslationKey.deleteWithFiles.tr,
                onPressed: () => _deleteSelectedItems(items, true, onlyDeleteLocal.value),
              )
            : null,
      ),
      customWidget: _buildOnlyLocalCheckbox(onlyDeleteLocal),
    );
  }

  /// 批量删除选中项：统一用一个加载弹窗，循环内复用 deleteItem 且不再单独提示。
  Future<void> _deleteSelectedItems(
    List<History> items,
    bool deleteFile, [
    bool onlyDeleteLocal = false,
  ]) async {
    final loadingDialog = dialogManager.loading(
      context,
      loadingText: TranslationKey.deleting.tr,
    );
    try {
      for (final item in items) {
        await deleteItem(
          item,
          deleteFile: deleteFile,
          onlyDeleteLocal: onlyDeleteLocal,
          showLoading: false,
        );
      }
      if (!mounted) {
        return;
      }
      snackbar.success(context, TranslationKey.deleteCompleted.tr);
      exitSelectionMode();
    } catch (err, stack) {
      logger.error(tag, err, stack);
      if (mounted) {
        snackbar.warn(context, TranslationKey.deletionFailed.tr);
      }
    } finally {
      await loadingDialog.close();
    }
  }

  /// 合并选中内容写入剪贴板，成功后退出多选。
  Future<void> _copyMergedContent() async {
    final merged = _selectionController.mergedContent;
    final ok = await clipboardManager.copy(ClipboardContentType.text, merged);
    if (!mounted) {
      return;
    }
    if (ok) {
      snackbar.success(context, TranslationKey.copySuccess.tr);
      exitSelectionMode();
    } else {
      snackbar.error(context, TranslationKey.copyFailed.tr);
    }
  }

  /// 导出选中的非文件历史；loadDataFunc 首次返回数据，之后返回空以结束分页。
  Future<void> _exportSelected() async {
    final onExport = widget.onExport;
    if (onExport == null) {
      return;
    }
    var loaded = false;
    await onExport((_) {
      if (loaded) {
        return <History>[];
      }
      loaded = true;
      return _selectionController.selectedItems
          .where((h) => !h.isFile)
          .toList();
    });
    if (mounted) {
      exitSelectionMode();
    }
  }

  /// 构建“仅本地删除”勾选项，单条与多选确认框复用。
  Widget _buildOnlyLocalCheckbox(ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) => CheckboxListTile(
        title: Text(TranslationKey.onlyLocal.tr),
        value: value,
        onChanged: (selected) => notifier.value = selected ?? false,
      ),
    );
  }
}
