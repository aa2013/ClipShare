import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/listeners/window_control_clicked_listener.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/widgets/clip_data_card_compact.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/filter/history_filter.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class HistoryWindow extends StatefulWidget {
  final WindowController windowController;
  final Map? args;

  const HistoryWindow({
    super.key,
    required this.windowController,
    this.args,
  });

  @override
  State<StatefulWidget> createState() {
    return _HistoryWindowState();
  }
}

class CompactClipData {
  final String devName;
  final ClipData data;

  const CompactClipData({required this.devName, required this.data});
}

class _HistoryWindowState extends State<HistoryWindow> with WindowListener, WindowControlClickedListener {
  final ScrollController _scrollController = ScrollController();
  List<CompactClipData> _list = [];
  bool _loadNewData = false;
  bool _loading = true;
  bool _showBackToTopButton = false;
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final windowControlService = Get.find<WindowControlService>();
  Timer? _timer;
  var searchFilter = SearchFilter();
  List<Device> allDevices = [];
  List<String> allTagNames = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
    windowControlService.addListener(this);
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      var method = MultiWindowMethod.values.byName(call.method);
      switch (method) {
        //更新通知
        case MultiWindowMethod.notify:
          refresh();
          break;
        //关闭（隐藏）窗口
        case MultiWindowMethod.showWindowFromHide:
          var position = args["position"];
          if (position != null) {
            var [x, y] = (position as List<dynamic>).cast<double>();
            windowManager.setPosition(Offset(x, y));
          }
          widget.windowController.show();
          windowManager.setAlwaysOnTop(true);
          searchFilter = SearchFilter();
          refresh();
          break;
        //关闭（隐藏）窗口
        case MultiWindowMethod.closeWindow:
          widget.windowController.hide();
          break;
        default:
      }
      //都不符合，返回空
      return Future.value();
    });
    refresh();
  }

  @override
  void onWindowMove() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      _timer = null;
      windowManager.getPosition().then((pos) {
        multiWindowChannelService.storeWindowPos(0, "history", pos);
      });
    });
  }

  @override
  void onCloseBtnClicked() {
    multiWindowChannelService.closeWindow(0, MultiWindowTag.history);
  }

  void _scrollListener() {
    if (_scrollController.offset == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _list = _list.sublist(0, min(_list.length, 20));
        setState(() {});
      });
    }
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200 && !_loadNewData) {
      refresh(true);
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

  Future<void> refresh([bool loadMore = false]) async {
    setState(() {
      _loadNewData = true;
    });
    await loadSearchCondition();
    return Future.delayed(const Duration(milliseconds: 500), () {
      var fromId = 0;
      if (loadMore) {
        fromId = _list.isEmpty ? 0 : _list.last.data.data.id;
      }
      return multiWindowChannelService.getHistories(0, fromId, searchFilter).then(
        (json) {
          var data = jsonDecode(json);
          var devInfos = data["devInfos"] as Map<String, dynamic>;
          var lst = History.fromJsonList(data["list"]);
          var res = List<CompactClipData>.empty(growable: true);
          for (var history in lst) {
            res.add(
              CompactClipData(
                devName: devInfos[history.devId] ?? "unknown",
                data: ClipData(history),
              ),
            );
          }
          setState(() {
            if (loadMore) {
              _list.addAll(res);
            } else {
              _list = res;
            }
            _loadNewData = false;
          });
        },
      ).whenComplete(
        () => setState(() {
          _loading = false;
        }),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    windowManager.removeListener(this);
    windowControlService.removeListener(this);
    _scrollController.removeListener(_scrollListener);
  }

  Future<void> loadSearchCondition() async {
    final devices = <Device>[];
    final tags = <String>[];
    await multiWindowChannelService.getAllDevices(0).then(
      ((json) {
        final data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
        devices.addAll(data.map(Device.fromJson));
      }),
    );
    await multiWindowChannelService.getAllTagNames(0).then((json) {
      var lst = (jsonDecode(json) as List<dynamic>).cast<String>();
      tags.addAll(lst);
    });
    setState(() {
      allDevices = devices;
      allTagNames = tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HistoryFilter(
            allDevices: allDevices,
            allTagNames: allTagNames,
            filter: searchFilter,
            loadSearchCondition: loadSearchCondition,
            isBigScreen: false,
            onChanged: (filter) {
              searchFilter = filter;
              setState(() {
                _loading = true;
              });
              refresh();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ConditionWidget(
                visible: _loading,
                replacement: ConditionWidget(
                  visible: _list.isEmpty,
                  replacement: ListView.builder(
                    itemCount: _list.length,
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (ctx, idx) {
                      return ClipDataCardCompact(
                        devName: _list[idx].devName,
                        clip: _list[idx].data,
                      );
                    },
                  ),
                  child: EmptyContent(),
                ),
                child: const Loading(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
