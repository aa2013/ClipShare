import 'dart:io';
import 'dart:math';

import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/listeners/multi_selection_pop_scope_disable_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/views/clipboard_detail_drawer.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/clip_data_card.dart';
import 'package:clipshare/app/widgets/clip_detail_dialog.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

import 'empty_content.dart';

class ClipListView extends StatefulWidget {
  final RxList<ClipData> list;
  final void Function() onRefreshData;
  final bool enableRouteSearch;
  final BorderRadiusGeometry? detailBorderRadius;
  final Future<List<ClipData>> Function(int minId)? onLoadMoreData;
  final void Function() onUpdate;
  final void Function(int id) onRemove;
  final bool imageMasonryGridViewLayout;
  final GetxController parentController;

  const ClipListView({
    super.key,
    required this.list,
    required this.onRefreshData,
    this.onLoadMoreData,
    this.detailBorderRadius,
    this.enableRouteSearch = false,
    required this.onUpdate,
    required this.onRemove,
    this.imageMasonryGridViewLayout = false,
    required this.parentController,
  });

  @override
  State<ClipListView> createState() => ClipListViewState();
}

class ClipListViewState extends State<ClipListView> with WidgetsBindingObserver implements MultiSelectionPopScopeDisableListener {
  final ScrollController _scrollController = ScrollController();
  final _scrollPhysics = const AlwaysScrollableScrollPhysics();
  int? _minId;
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final homeCtrl = Get.find<HomeController>();
  static bool _loadingNewData = false;
  var _showBackToTopButton = false;
  final String tag = "ClipListView";
  var _selectMode = false;
  final _selectedItems = <ClipData>{};
  MenuController codeMenuController = MenuController();

  bool get isBigScreen => MediaQuery.of(context).size.width >= Constants.smallScreenWidth;

  bool get showHistoryRight => MediaQuery.of(context).size.width >= Constants.showHistoryRightWidth;

  @override
  void initState() {
    super.initState();
    _loadingNewData = false;
    if (widget.list.isNotEmpty) {
      _minId = widget.list.last.data.id;
    }
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    final homeController = Get.find<HomeController>();
    homeController.registerMultiSelectionPopScopeDisableListener(this);
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 释放资源
    _scrollController.dispose();
    final homeController = Get.find<HomeController>();
    homeController.removeMultiSelectionPopScopeDisableListener(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  ///加载更多数据
  void _loadMoreData() {
    if (_loadingNewData || _minId == null) {
      return;
    }
    _loadingNewData = true;
    Future<List<ClipData>> f;
    if (widget.onLoadMoreData == null) {
      f = dbService.historyDao.getHistoriesPage(appConfig.userId, _minId!).then((lst) => ClipData.fromList(lst));
    } else {
      f = widget.onLoadMoreData!.call(_minId!);
    }
    f.then((List<ClipData> list) {
      if (list.isNotEmpty) {
        _minId = list[list.length - 1].data.id;
        widget.list.addAll(list);
        removeDuplicates();
        _sortList();
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadingNewData = false;
      });
    });
  }

  ///移除重复项
  void removeDuplicates() {
    Map<int, ClipData> map = {};
    for (var clip in widget.list) {
      map[clip.data.id] = clip;
    }
    widget.list.value = map.values.toList(growable: true);
  }

  ///滚动监听
  void _scrollListener() {
    if (_scrollController.offset == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        var tmpList = widget.list.sublist(0, min(widget.list.length, 100));
        widget.list.value = tmpList;
        if (tmpList.isNotEmpty) {
          _minId = tmpList.last.data.id;
        }
        setState(() {});
      });
    }
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200 && !_loadingNewData) {
      _loadMoreData();
    }
    if (_scrollController.offset >= 300) {
      if (!_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = true;
        });
      }
    } else {
      if (_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    }
  }

  ///排序 list
  void _sortList() {
    widget.list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }

  ///删除项目
  Future<void> deleteItem(ClipData item, [bool deleteFile = false]) async {
    await dbService.historyDao.deleteByCascade(item.data.id);
    widget.onRemove(item.data.id);
    final historyController = Get.find<HistoryController>();
    //通知子窗体
    historyController.notifyHistoryWindow();
    //添加删除记录
    var opRecord = OperationRecord.fromSimple(
      Module.history,
      OpMethod.delete,
      item.data.id,
    );
    //通知其他设备
    dbService.opRecordDao.addAndNotify(opRecord);
    if (!item.isImage && !item.isFile) {
      return;
    }
    //如果是图片，删除并更新媒体库
    final path = item.data.content;
    var file = File(path);
    if (!file.existsSync()) return;
    file.deleteSync();
    if (item.isImage && Platform.isAndroid) {
      androidChannelService.notifyMediaScan(path);
    }
  }

  ///渲染列表项
  Widget renderItem(int i) {
    var item = widget.list[i];
    onRemoveClicked(ClipData item) {
      Global.showTipsDialog(
        context: context,
        text: TranslationKey.deleteRecordAck.tr,
        title: TranslationKey.deleteTips.tr,
        showCancel: true,
        showNeutral: item.isFile || item.isImage,
        neutralText: TranslationKey.deleteWithFiles.tr,
        onOk: () => deleteItem(item),
        onNeutral: () => deleteItem(item, true),
      );
    }

    return ClipDataCard(
      clip: widget.list[i],
      imageMode: widget.imageMasonryGridViewLayout,
      routeToSearchOnClickChip: widget.enableRouteSearch,
      selectMode: _selectMode,
      selected: _selectedItems.contains(item),
      onTap: () {
        print("on clicked");
        if (_selectMode) {
          if (_selectedItems.contains(item)) {
            _selectedItems.remove(item);
          } else {
            _selectedItems.add(item);
          }
          setState(() {});
        } else {
          var data = widget.list[i];
          if (isBigScreen) {
            homeCtrl.openEndDrawer(
              drawer: ClipboardDetailDrawer(clipData: data),
            );
          } else {
            showModalBottomSheet(
              isScrollControlled: true,
              clipBehavior: Clip.antiAlias,
              context: context,
              elevation: 100,
              builder: (BuildContext context) {
                return ClipDetailDialog(
                  dlgContext: context,
                  clip: data,
                  onUpdate: widget.onUpdate,
                  onRemoveClicked: onRemoveClicked,
                );
              },
            );
          }
        }
      },
      onLongPress: () {
        appConfig.enableMultiSelectionMode(
          controller: widget.parentController,
          selectionTips: TranslationKey.multiDelete.tr,
        );
        _selectMode = true;
        _selectedItems.add(item);
        setState(() {});
      },
      onDoubleTap: () async {
        if (widget.list[i].isFile) {
          await OpenFile.open(widget.list[i].data.content);
          return;
        }
        appConfig.innerCopy = true;
        History history = widget.list[i].data;
        var type = ClipboardContentType.parse(history.type);
        final res = await clipboardManager.copy(type, history.content);
        if (res) {
          Global.showSnackBarSuc(context: context, text: TranslationKey.copySuccess.tr);
        } else {
          Global.showSnackBarErr(context: context, text: TranslationKey.copyFailed.tr);
        }
      },
      onUpdate: widget.onUpdate,
      onRemoveClicked: onRemoveClicked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: appConfig.bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                return Future.delayed(
                  const Duration(milliseconds: 500),
                  widget.onRefreshData,
                );
              },
              child: Obx(
                () => ConditionWidget(
                  visible: widget.list.isEmpty,
                  replacement: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return Obx(() {
                        final isImageMode = widget.imageMasonryGridViewLayout;
                        final maxWidth = isImageMode ? 200.0 : 395;
                        final showMore = (appConfig.showMoreItemsInRow && !appConfig.isSmallScreen) || isImageMode;
                        final count = showMore ? max(2, constraints.maxWidth ~/ maxWidth) : 1;
                        return Listener(
                          child: MasonryGridView.count(
                            crossAxisCount: count,
                            mainAxisSpacing: 4,
                            shrinkWrap: true,
                            itemCount: widget.list.length,
                            controller: _scrollController,
                            physics: _scrollPhysics,
                            itemBuilder: (context, index) {
                              if (isImageMode) {
                                return renderItem(index);
                              } else {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                    minHeight: 80,
                                  ),
                                  child: renderItem(index),
                                );
                              }
                            },
                          ),
                          onPointerSignal: (e) {
                            if (e is PointerScrollEvent) {
                              // 已经滚动到底部，仍然尝试滚动
                              if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
                                Log.debug(tag, "Try loading more data at the bottom");
                                _loadMoreData();
                              }
                            }
                          },
                        );
                      });
                    },
                  ),
                  child: Stack(
                    children: [
                      ListView(),
                      EmptyContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                Visibility(
                  visible: _selectMode,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(right: 10),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "${_selectedItems.length} / ${widget.list.length}",
                          style: TextStyle(
                            fontSize: 20,
                            color: appConfig.currentIsDarkMode ? Colors.white : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: _selectMode,
                  child: Tooltip(
                    message: TranslationKey.deselect.tr,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: FloatingActionButton(
                        onPressed: () {
                          _cancelSelectionMode();
                          appConfig.disableMultiSelectionMode(true);
                          setState(() {});
                        },
                        heroTag: 'deselectHistory',
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: _selectMode && _selectedItems.isNotEmpty,
                  child: Tooltip(
                    message: TranslationKey.delete.tr,
                    child: Container(
                      margin: _showBackToTopButton ? const EdgeInsets.only(right: 10) : null,
                      child: FloatingActionButton(
                        onPressed: () {
                          void multiDelete(bool deleteFile) async {
                            Get.back();
                            Global.showLoadingDialog(
                              context: context,
                              loadingText: TranslationKey.deleting.tr,
                            );
                            for (var item in _selectedItems) {
                              await deleteItem(item, deleteFile);
                            }
                            Get.back();
                            Global.showSnackBarSuc(
                              context: context,
                              text: TranslationKey.deleteCompleted.tr,
                            );
                            _selectedItems.clear();
                            _selectMode = false;
                            appConfig.disableMultiSelectionMode(true);
                            setState(() {});
                          }

                          Global.showTipsDialog(
                            context: context,
                            text: TranslationKey.clipListViewDeleteAsk.trParams({"length": _selectedItems.length.toString()}),
                            showCancel: true,
                            autoDismiss: false,
                            showNeutral: _selectedItems.any((item) => item.isFile),
                            neutralText: TranslationKey.deleteWithFiles.tr,
                            onCancel: () {
                              Navigator.pop(context);
                            },
                            onNeutral: () => multiDelete(true),
                            onOk: () => multiDelete(false),
                          );
                        },
                        heroTag: 'deleteHistory',
                        child: const Icon(Icons.delete_forever),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: _showBackToTopButton,
                  child: Tooltip(
                    message: TranslationKey.backToTop.tr,
                    child: FloatingActionButton(
                      onPressed: () {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                      heroTag: 'backToTop',
                      child: const Icon(Icons.arrow_upward), // 可以选择其他图标
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///取消选择模式
  void _cancelSelectionMode() {
    _selectedItems.clear();
    _selectMode = false;
    setState(() {});
  }

  @override
  void onPopScopeDisableMultiSelection() {
    _cancelSelectionMode();
  }
}
