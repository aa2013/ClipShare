import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/utils/extensions/history_data_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
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
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/clip/clip_data_card.dart';
import 'package:clipshare/app/widgets/dialog/clip_detail_dialog.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:open_file_plus/open_file_plus.dart';

import 'empty_content.dart';

part 'clip_list_view/clip_list_body.dart';
part 'clip_list_view/clip_list_fab.dart';
part 'clip_list_view/clip_list_item_renderer.dart';

class ClipListView extends StatefulWidget {
  final List<ClipData> list;
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

class ClipListViewState extends State<ClipListView>
    with WidgetsBindingObserver
    implements MultiSelectionPopScopeDisableListener {
  final ScrollController _scrollController = ScrollController();
  final _scrollPhysics = const AlwaysScrollableScrollPhysics();
  int? _minId;
  int? _lastListTailId;
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

  bool get isBigScreen =>
      MediaQuery.of(context).size.width >= Constants.smallScreenWidth;

  bool get showHistoryRight =>
      MediaQuery.of(context).size.width >= Constants.showHistoryRightWidth;

  @override
  void initState() {
    super.initState();
    _loadingNewData = false;
    if (widget.list.isNotEmpty) {
      _minId = widget.list.last.data.id;
      _lastListTailId = _minId;
    }
    WidgetsBinding.instance.addObserver(this);
    final homeController = Get.find<HomeController>();
    homeController.registerMultiSelectionPopScopeDisableListener(this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant ClipListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tailId = widget.list.isEmpty ? null : widget.list.last.data.id;
    if (_lastListTailId != tailId) {
      _lastListTailId = tailId;
      _minId = tailId;
      _selectedItems.removeWhere((item) => !widget.list.contains(item));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _loadMoreData() {
    if (_loadingNewData || _minId == null) {
      return;
    }
    _loadingNewData = true;
    Future<List<ClipData>> f;
    if (widget.onLoadMoreData == null) {
      f = dbService.historyDao
          .getHistoriesPage(appConfig.userId, _minId!)
          .then((lst) => ClipData.fromList(lst));
    } else {
      f = widget.onLoadMoreData!.call(_minId!);
    }
    f.then((List<ClipData> list) {
      if (list.isNotEmpty) {
        _minId = list[list.length - 1].data.id;
        _lastListTailId = _minId;
        widget.list.addAll(list);
        removeDuplicates();
        _sortList();
      }
      Future.delayed(500.ms, () {
        _loadingNewData = false;
      });
    });
  }

  void removeDuplicates() {
    Map<int, ClipData> map = {};
    for (var clip in widget.list) {
      map[clip.data.id] = clip;
    }
    widget.list
      ..clear()
      ..addAll(map.values);
  }

  void _scrollListener() {
    if (_scrollController.offset == 0) {
      Future.delayed(100.ms, () {
        var tmpList = widget.list.sublist(0, min(widget.list.length, 100));
        widget.list
          ..clear()
          ..addAll(tmpList);
        if (tmpList.isNotEmpty) {
          _minId = tmpList.last.data.id;
          _lastListTailId = _minId;
        }
        setState(() {});
      });
    }
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

  void _sortList() {
    widget.list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }

  Future<void> deleteItem(ClipData item,
      {bool deleteFile = false, bool onlyDeleteLocal = false}) async {
    await dbService.historyDao.deleteByCascade(item.data.id);
    widget.onRemove(item.data.id);
    final historyController = Get.find<HistoryController>();
    historyController.notifyHistoryWindow();
    if (!onlyDeleteLocal) {
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.delete,
        item.data.id,
      );
      dbService.opRecordDao.addAndNotify(opRecord);
    }
    if (!item.isImage && !item.isFile) {
      return;
    }
    final path = item.data.content;
    var file = File(path);
    if (!file.existsSync()) return;
    file.deleteSync();
    if (item.isImage && Platform.isAndroid) {
      androidChannelService.notifyMediaScan(path);
    }
  }

  void _enableSelectMode() {
    if (_selectMode) {
      return;
    }
    appConfig.enableMultiSelectionMode(
      controller: widget.parentController,
    );
    _selectMode = true;
    setState(() {});
  }

  void _toggleSelectState(ClipData data) {
    if (!_selectMode) {
      return;
    }
    if (_selectedItems.contains(data)) {
      _selectedItems.remove(data);
    } else {
      _selectedItems.add(data);
    }
    setState(() {});
  }

  void _refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

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
