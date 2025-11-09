
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/chart/bar_chart_item.dart';
import 'package:clipshare/app/data/models/chart/pie_data_item.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:get/get.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class StatisticsController extends GetxController {
  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();

  final startMonth = '2024-01'.obs;
  final endMonth = '2024-10'.obs;
  final historyTypeCntItems = RxList<BarChartItem>([]);
  final historyTagCntItems = RxList<BarChartItem>([]);
  final syncRatePieItems = RxList<PieDataItem>([]);
  final historyCntForDeviceItems = RxList<BarChartItem>([]);

  bool get isAllEmpty =>
      historyTypeCntItems.isEmpty &&
      historyTagCntItems.isEmpty &&
      syncRatePieItems.isEmpty &&
      historyCntForDeviceItems.isEmpty;

  //region 生命周期
  @override
  void onInit() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month);
    DateTime currentDate = DateTime(now.year, now.month);
    startMonth.value = firstDayOfMonth.format("yyyy-MM");
    endMonth.value = currentDate.format("yyyy-MM");
    super.onInit();
  }

  @override
  void onReady() {
    refreshData();
  }

  //endregion

  //region 页面方法
  int contentTypeNameCompare(String a, String b) {
    return HistoryContentType.parse(a)
        .order
        .compareTo(HistoryContentType.parse(b).order);
  }

  void padBarItems(
    List<BarChartItem> items, [
    int Function(String a, String b)? nameCompare,
  ]) {
    Map<String, Set<String>> groupIndexes = {};
    Set<String> allNames = {};
    for (var item in items) {
      final index = item.index;
      allNames.add(item.name);
      if (groupIndexes.containsKey(index)) {
        groupIndexes[index]!.add(item.name);
      } else {
        groupIndexes[index] = {item.name};
      }
    }
    //填充
    for (var month in groupIndexes.keys) {
      var groupNames = groupIndexes[month]!;
      var diff = allNames.difference(groupNames);
      if (diff.isEmpty) continue;
      for (var name in diff) {
        items.add(BarChartItem(name: name, index: month, value: 0));
      }
    }
    items.sort((a, b) {
      int compareIndex = a.index.compareTo(b.index);
      if (compareIndex == 0) {
        if (nameCompare != null) {
          return nameCompare(a.name, b.name);
        }
        return a.name.compareTo(b.name);
      } else {
        return compareIndex;
      }
    });
  }

  void selectRangeMonth() async {
    var res = await showMonthRangePicker(context: Get.context!);
    if (res != null) {
      startMonth.value = res[0].format("yyyy-MM");
      endMonth.value = res[1].format("yyyy-MM");
    }
  }

  ///刷新页面
  Future<void> refreshData() async {
    await loadHistoryTypeCnt();
    await loadHistoryTagCnt();
    await loadHistoryCntForDevice();
  }

  ///不同类别的数量
  Future<void> loadHistoryTypeCnt() async {
    final typeCntList = await dbService.historyDao.getHistoryTypeCnt(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    var res = typeCntList
        .map((e) => BarChartItem(name: e.type, index: e.date, value: e.cnt))
        .toList();
    padBarItems(res, contentTypeNameCompare);
    historyTypeCntItems.value = res;
  }

  ///各设备同步数量
  Future<void> loadHistoryCntForDevice() async {
    final res = await dbService.historyDao.getHistoryCntForDevice(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    final tmp = res
        .map((e) => BarChartItem(name: e.devName, value: e.cnt, index: e.month))
        .toList();
    padBarItems(tmp);
    historyCntForDeviceItems.value = tmp;
    String selfId = appConfig.device.guid;
    var sync = 0;
    var self = 0;
    for (var item in res) {
      if (item.devId == selfId) {
        self += item.cnt;
      } else {
        sync += item.cnt;
      }
    }
    if (res.isNotEmpty) {
      syncRatePieItems.value = [
        PieDataItem(TranslationKey.pieDataStatisticsLocalItemLabel.tr, self),
        PieDataItem(TranslationKey.pieDataStatisticsSyncItemLabel.tr, sync),
      ];
    } else {
      syncRatePieItems.value = [];
    }
  }

  ///各个标签的引用数量
  Future<void> loadHistoryTagCnt() async {
    final res = await dbService.historyTagDao.getHistoryTagCnt(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    historyTagCntItems.value = res
        .map(
          (e) => BarChartItem(name: e.tagName, index: e.tagName, value: e.cnt),
        )
        .toList();
  }
//endregion
}
