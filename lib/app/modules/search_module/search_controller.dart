import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchController extends GetxController with WidgetsBindingObserver {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();

  //region 属性
  static const tag = "SearchController";
  final list = List<ClipData>.empty(growable: true).obs;
  List<Device> allDevices = List.empty();
  List<String> allTagNames = List.empty();
  int? _minId;
  final loading = true.obs;
  var exporting = false;
  var cancelExporting = false;

  //region 搜索相关
  Set<String> get selectedTags => filter.value.tags;

  Set<String> get selectedDevIds => filter.value.devIds;

  String get searchStartDate => filter.value.startDate;

  String get searchEndDate => filter.value.endDate;
  final _searchType = HistoryContentType.all.obs;

  HistoryContentType get searchType => _searchType.value;

  set searchType(value) => _searchType.value = value;

  bool get searchOnlyNoSync => filter.value.onlyNoSync;
  final filter = SearchFilter().obs;

  //endregion

  String get typeValue => HistoryContentType.typeMap.keys.contains(searchType.label) ? HistoryContentType.typeMap[searchType.label]! : "";

  final _screenWidth = Get.width.obs;

  set screenWidth(value) => _screenWidth.value = value;

  double get screenWidth => _screenWidth.value;

  bool get isBigScreen => screenWidth >= Constants.smallScreenWidth;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    loadFromExternalParams(null, null);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    appConfig.disableMultiSelectionMode(true);
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
    //加载数据
    refreshData();
  }

  ///重新加载列表
  void refreshData() {
    _minId = null;
    loadSearchCondition();
    loadData(_minId).then((lst) {
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
      allTagNames = lst;
    });
    //加载所有设备名
    await dbService.deviceDao.getAllDevices(appConfig.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(appConfig.device);
      tmpLst.addAll(lst);
      allDevices = tmpLst;
    });
  }

  ///加载数据
  Future<List<ClipData>> loadData(int? minId) {
    //加载搜索结果的前100条
    return dbService.historyDao
        .getHistoriesPageByWhere(
      appConfig.userId,
      minId ?? 0,
      filter.value.content,
      typeValue,
      selectedTags.toList(),
      selectedDevIds.toList(),
      searchStartDate,
      searchEndDate,
      searchOnlyNoSync,
      minId != null,
    )
        .then((list) {
      return ClipData.fromList(list);
    });
  }

  //region 导出

  ///导出为 excel
  Future<bool> export2Excel() async {
    if (exporting) return false;
    exporting = true;
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    final Style dateTimeStyle = workbook.styles.add('CustomDateTimeStyle');
    dateTimeStyle.numberFormat = 'yyyy-MM-dd HH:mm:ss';
    int lastId = 0;
    //第一行是标题头，内容从第二行开始
    int rowNum = 2;
    bool ignoreTop = false;
    _addExcelHeader(sheet);
    while (true) {
      if (cancelExporting) {
        return false;
      }
      var list = await dbService.historyDao.getHistoriesPageByFilter(
        appConfig.userId,
        filter.value,
        ignoreTop,
        lastId,
      );
      //首次查询加载置顶，后续就不要重复加载了
      if (ignoreTop == false) {
        ignoreTop = true;
      }
      if (list.isEmpty) {
        break;
      }
      lastId = list.map((item) => item.id).reduce(min);
      for (var item in list) {
        //转换为excel数据
        _add2ExcelSheet(sheet, item, rowNum++, dateTimeStyle);
      }
    }
    Log.debug(tag, "add2ExcelSheet finished");
    final List<int> bytes = workbook.saveAsStream();
    Log.debug(tag, "workbook bytes: ${bytes.length}(${bytes.length.sizeStr})");
    await FileUtil.exportFileBytes(
      TranslationKey.export2Excel.tr,
      TranslationKey.export2ExcelFileName.tr,
      Uint8List.fromList(bytes),
    );
    workbook.dispose();
    return true;
  }

  ///添加导出excel的头（第一行）
  void _addExcelHeader(Worksheet sheet) {
    sheet.getRangeByName("A1").setText("时间");
    sheet.setColumnWidthInPixels(1, 150);
    sheet.getRangeByName("B1").setText("类型");
    sheet.getRangeByName("C1").setText("设备");
    sheet.getRangeByName("D1").setText("是否置顶");
    sheet.getRangeByName("E1").setText("内容");
    sheet.setColumnWidthInPixels(5, 570);
    sheet.getRangeByName("F1").setText("内容长度");
  }

  ///将历史数据添加到excel对象中
  void _add2ExcelSheet(Worksheet sheet, History history, int rowNum, Style timeStyle) {
    if (rowNum <= 0) {
      throw ArgumentError("rowNum cannot less than 0");
    }
    final clip = ClipData(history);
    final time = DateTime.parse(history.time);
    final type = HistoryContentType.parse(history.type);
    if (type == HistoryContentType.file) {
      //文件同步跳过
      return;
    }
    final devName = devService.getName(history.devId);
    final size = clip.sizeText;
    sheet.getRangeByName("A$rowNum")
      ..cellStyle = timeStyle
      ..setDateTime(time);
    sheet.getRangeByName("B$rowNum").setText(type.label);
    sheet.getRangeByName("C$rowNum").setText(devName);
    sheet.getRangeByName("D$rowNum").setNumber(history.top ? 1 : 0);
    if (clip.isImage) {
      final file = File(history.content);
      final cell = sheet.getRangeByName("E$rowNum");
      sheet.setRowHeightInPixels(rowNum, 100);
      final rowHeight = cell.rowHeight;
      final cellWidth = cell.columnWidth;
      if (file.existsSync()) {
        final List<int> bytes = file.readAsBytesSync();
        //only supports png and jpeg
        final picture = sheet.pictures.addStream(rowNum, 5, bytes);
        //rowHeight取出来是单位pt，转为像素需要 * 1.33
        picture.height = min(rowHeight * 1.33, 100).toInt(); // 限制高度
        picture.width = min(cellWidth * 1.33, 200).toInt(); // 限制宽度
      }
    } else {
      sheet.getRangeByName("E$rowNum").setText(history.content);
    }
    sheet.getRangeByName("F$rowNum").setText(size);
  }
//endregion
//endregion
}
