import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
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

class SearchController extends GetxController with WidgetsBindingObserver {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
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
  var exporting = false;
  var cancelExporting = false;

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
    loadSearchCondition().whenComplete(
      () {
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
          onExportBtnClicked: _export,
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

  //region 导出
  void _export() {
    var loadingController = LadingProgressController();
    Global.showTipsDialog(
      context: Get.context!,
      text: TranslationKey.historyOutputTips.tr,
      onOk: () {
        Global.showLoadingDialog(
          context: Get.context!,
          loadingText: TranslationKey.exporting.tr,
          showCancel: true,
          controller: loadingController,
          onCancel: () {
            cancelExporting = true;
            exporting = false;
          },
        );
        export2Excel(loadingController)
            .then((result) {
              //关闭进度动画
              Get.back();
              //手动取消
              if (!exporting) {
                return;
              }
              if (result) {
                Global.showSnackBarSuc(context: Get.context!, text: TranslationKey.outputSuccess.tr);
              } else {
                Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.outputFailed.tr);
              }
            })
            .catchError((err, stack) {
              //关闭进度动画
              Get.back();
              Global.showTipsDialog(
                context: Get.context!,
                title: TranslationKey.outputFailed.tr,
                text: "$err. $stack",
              );
            })
            .whenComplete(() {
              //更新状态
              exporting = false;
              cancelExporting = false;
            });
      },
      showCancel: true,
    );
  }

  ///导出为 excel
  Future<bool> export2Excel(LadingProgressController loadingController) async {
    if (exporting) return false;
    exporting = true;
    int lastId = 0;
    //第一行是标题头，内容从第二行开始
    int rowNum = 2;
    var histories = List<History>.empty(growable: true);
    while (true) {
      if (cancelExporting) {
        return false;
      }
      var list = await dbService.historyDao.getHistoriesPageByFilter(
        appConfig.userId,
        searchFilter,
        true,
        lastId,
      );
      if (list.isEmpty) {
        break;
      }
      histories.addAll(list);
      lastId = list.last.id;
    }
    histories.sort((a, b) {
      // 首先按 top 排序（true 在前，false 在后）
      if (a.top != b.top) {
        return a.top ? -1 : 1; // true 在前，所以返回 -1
      }
      // 如果 top 相同，则按 id 降序排列
      return b.id.compareTo(a.id); // 降序：b.id - a.id
    });
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    _addExcelHeader(sheet);
    final Style dateTimeStyle = workbook.styles.add('CustomDateTimeStyle');
    dateTimeStyle.numberFormat = 'yyyy-MM-dd HH:mm:ss';
    dateTimeStyle.vAlign = VAlignType.center;
    final Style vAlign = workbook.styles.add('verticalCenter');
    vAlign.vAlign = VAlignType.center;

    var lastTime = DateTime.now();
    loadingController.update(0, histories.length);

    for (var i = 0; i < histories.length; i++) {
      var item = histories[i];
      if (cancelExporting) {
        return false;
      }
      //转换为excel数据(对于内容超过32767字符的会合并单元格，统计使用了多少行)
      final useRows = await _add2ExcelSheet(sheet, item, rowNum, dateTimeStyle, vAlign);
      rowNum += useRows;
      var now = DateTime.now();
      if (now.difference(lastTime).inMilliseconds.abs() > 10) {
        loadingController.update(i + 1);
      }
      lastTime = now;

      if (ClipData(item).isImage) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    loadingController.update(histories.length);
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
    sheet.getRangeByName("D1").setText("来源");
    sheet.getRangeByName("E1").setText("是否置顶");
    sheet.getRangeByName("F1").setText("内容");
    sheet.setColumnWidthInPixels(6, 570);
    sheet.getRangeByName("G1").setText("内容长度");
  }

  ///将历史数据添加到excel对象中，返回值为使用的行数
  Future<int> _add2ExcelSheet(Worksheet sheet, History history, int rowNum, Style timeStyle, Style vAlignStyle) async {
    if (rowNum <= 0) {
      throw ArgumentError("rowNum cannot less than 0");
    }
    final clip = ClipData(history);
    final time = DateTime.parse(history.time);
    final type = HistoryContentType.parse(history.type);
    if (type == HistoryContentType.file) {
      //文件同步跳过
      return 0;
    }
    var rowsOffset = 0;
    const maxCellLength = 32767;
    //转换 unicode 控制字符 \u0000 ~ \u001f，这些字符会导致 excel 打开失败
    //需要替换为 _x0000_ 这样的
    final content = history.content.replaceAllMapped(
      RegExp(r'[\x00-\x1F]'),
      (match) => '_x${match.group(0)!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}_',
    );
    if (content.length > maxCellLength) {
      //单个单元格最多支持32767字符，否则会导致excel打开失败
      rowsOffset = (content.length / maxCellLength).ceil() - 1;
    }
    final devName = devService.getName(history.devId);
    final size = clip.sizeText;
    sheet.getRangeByName("A$rowNum:A${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = timeStyle
      ..setDateTime(time);
    sheet.getRangeByName("B$rowNum:B${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(type.label);
    sheet.getRangeByName("C$rowNum:C${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(devName);
    final sourceService = Get.find<ClipboardSourceService>();
    var source = "";
    if (history.source != null) {
      final app = sourceService.getAppInfoByAppId(history.source!);
      if (app != null) {
        source = app.name;
      }
    }
    sheet.getRangeByName("D$rowNum:D${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(source);
    sheet.getRangeByName("E$rowNum:E${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setNumber(history.top ? 1 : 0);
    if (clip.isImage) {
      final file = File(history.content);
      final cell = sheet.getRangeByName("F$rowNum");
      sheet.setRowHeightInPixels(rowNum, 100);
      final rowHeight = cell.rowHeight;
      final cellWidth = cell.columnWidth;
      if (file.existsSync()) {
        final List<int> bytes = await file.readAsBytes();
        //only supports png and jpeg
        final picture = sheet.pictures.addStream(rowNum, 5, bytes);
        //rowHeight取出来是单位pt，转为像素需要 * 1.33
        picture.height = min(rowHeight * 1.33, 100).toInt(); // 限制高度
        picture.width = min(cellWidth * 1.33, 200).toInt(); // 限制宽度
      }
    } else {
      for (var i = 0; i <= rowsOffset; i++) {
        final start = i * maxCellLength;
        final end = min((i + 1) * maxCellLength, content.length);
        sheet.getRangeByName("F${rowNum + i}").setText(content.substring(start, end));
      }
    }
    sheet.getRangeByName("G$rowNum:G${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(size);
    return rowsOffset + 1;
  }

  //endregion
  //endregion
}
