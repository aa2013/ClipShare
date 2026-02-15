import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/device_remove_listener.dart';
import 'package:clipshare/app/listeners/tag_changed_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/filter/history_filter.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchController extends GetxController with WidgetsBindingObserver implements DeviceRemoveListener, DevAliveListener, TagChangedListener {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final sktService = Get.find<SocketService>();
  final tagService = Get.find<TagService>();
  final multiWindowService = Get.find<MultiWindowChannelService>();
  final sourceService = Get.find<ClipboardSourceService>();

  //region 属性
  static const tag = "SearchController";
  final list = List<ClipData>.empty(growable: true).obs;
  final _allDevices = <Device>[].obs;
  final _allTagNames = <String>[].obs;

  List<Device> get allDevices => _allDevices.value;

  List<String> get allTagNames => _allTagNames.value;
  int? _minId;
  final loading = true.obs;
  final filterLoading = true.obs;

  //region 搜索相关
  Set<String> get selectedTags => filterController.selectedTags.value;

  Set<String> get selectedDevIds => filterController.selectedDevIds.value;

  Set<String> get selectedAppIds => filterController.selectedAppIds.value;

  String get searchStartDate => filterController.startDate.value;

  String get searchEndDate => filterController.endDate.value;
  final _searchType = HistoryContentType.all.obs;

  HistoryContentType get searchType => _searchType.value;

  set searchType(value) => _searchType.value = value;

  bool get searchOnlyNoSync => filterController.onlyNoSync.value;

  //endregion

  String get typeValue => HistoryContentType.typeMap.keys.contains(searchType.label) ? HistoryContentType.typeMap[searchType.label]! : "";

  final _screenWidth = Get.width.obs;

  set screenWidth(value) => _screenWidth.value = value;

  double get screenWidth => _screenWidth.value;

  bool get isBigScreen => screenWidth >= Constants.smallScreenWidth;
  late final HistoryFilterController filterController;

  SearchFilter get searchFilter => filterController.filter..type = _searchType.value;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    connRegService.addDevAliveListener(this);
    devService.addDevRemoveListener(this);
    tagService.addListener(this);
    loadSearchCondition().whenComplete(
      () {
        final historyController = Get.find<HistoryController>();

        Future<List<History>> loadDataFunc(int lastId) => dbService.historyDao.getHistoriesPageByFilter(
          appConfig.userId,
          searchFilter,
          true,
          lastId,
        );
        filterController = HistoryFilterController(
          allDevices: allDevices,
          allTagNames: allTagNames,
          allSources: sourceService.appInfos,
          isBigScreen: isBigScreen,
          loadSearchCondition: loadSearchCondition,
          showContentTypeFilter: false,
          onChanged: (filter) {
            refreshData();
          },
          onSearchBtnClicked: refreshData,
          filter: SearchFilter(),
          onExportBtnClicked: () => historyController.export(loadDataFunc),
        );
        filterLoading.value = false;
        loadFromExternalParams(null, null);
        refreshData();
        super.onInit();
      },
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    appConfig.disableMultiSelectionMode(true);
    connRegService.removeDevAliveListener(this);
    devService.removeDevRemoveListener(this);
    tagService.removeListener(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {}
  }

  //endregion

  //region 页面方法

  void updateData(
    bool Function(History history) where,
    void Function(History history) cb, [
    bool shouldRefresh = false,
  ]) {
    var matchData = false;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      //查找符合条件的数据
      if (where(item.data)) {
        //更新数据
        cb(item.data);
        matchData = true;
      }
    }
    if (matchData) {
      final tmpList = List.of(list);
      list.value = tmpList;
    }
  }

  ///根据外部参数刷新数据
  void loadFromExternalParams(String? devId, String? tagName) {
    //初始化搜索参数
    if (devId != null) {
      selectedDevIds.assignAll({devId});
      if (tagName == null) {
        selectedTags.clear();
      }
    }
    if (tagName != null) {
      selectedTags.assignAll({tagName});
      if (devId == null) {
        selectedDevIds.clear();
      }
    }
  }

  ///重新加载列表
  Future<void> refreshData() async {
    _minId = null;
    await loadSearchCondition();
    await loadData(_minId).then((lst) {
      list.value = lst;
      loading.value = false;
    });
  }

  void sortList() {
    list.sort((a, b) => b.data.compareTo(a.data));
  }

  ///加载搜索条件
  Future<void> loadSearchCondition() async {
    //加载所有标签名
    await dbService.historyTagDao.getAllTagNames().then((lst) {
      _allTagNames.value = lst;
    });
    //加载所有设备名
    await dbService.deviceDao.getAllDevices(appConfig.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(appConfig.device);
      tmpLst.addAll(lst);
      _allDevices.value = tmpLst;
    });
  }

  ///加载数据
  Future<List<ClipData>> loadData(int? minId) {
    //加载搜索结果的前100条
    return dbService.historyDao
        .getHistoriesPageByWhere(
          appConfig.userId,
          minId ?? 0,
          filterController.content.value,
          typeValue,
          selectedTags.toList(),
          selectedDevIds.toList(),
          selectedAppIds.toList(),
          searchStartDate,
          searchEndDate,
          searchOnlyNoSync,
          minId != null,
        )
        .then((list) {
          return ClipData.fromList(list);
        });
  }

  //endregion

  //region 设备变更监听

  @override
  Future<void> onPaired(DevInfo dev, int uid, bool result, String? address) async {
    await loadSearchCondition();
    filterController.setAllDevices(_allDevices);
    filterController.setAllTagNames(_allTagNames);
    if (appConfig.historyWindow != null) {
      multiWindowService.updateAllBaseData(appConfig.historyWindow!.windowId);
    }
  }

  @override
  void onRemove(String devId) {
    filterController.setAllDevices(_allDevices);
    filterController.setAllTagNames(_allTagNames);
    if (appConfig.historyWindow != null) {
      multiWindowService.updateAllBaseData(appConfig.historyWindow!.windowId);
    }
  }

  @override
  void onCancelPairing(DevInfo dev) {
    // ignored
  }

  @override
  void onConnected(DevInfo info, AppVersion minVersion, AppVersion version, TransportProtocol protocol) {
    // ignored
  }

  @override
  void onDisconnected(String devId) {
    // ignored
  }

  @override
  void onForget(DevInfo dev, int uid) {
    // ignored
  }

  //endregion

  //region 新标签变更监听

  @override
  Future<void> onDistinctAdd(String tagName) async {
    await loadSearchCondition();
    filterController.setAllTagNames(_allTagNames);
    if (appConfig.historyWindow != null) {
      multiWindowService.updateAllBaseData(appConfig.historyWindow!.windowId);
    }
  }

  @override
  Future<void> onDistinctRemove(String tagName) async {
    await loadSearchCondition();
    filterController.setAllTagNames(_allTagNames);
    if (appConfig.historyWindow != null) {
      multiWindowService.updateAllBaseData(appConfig.historyWindow!.windowId);
    }
  }

  //endregion
}
