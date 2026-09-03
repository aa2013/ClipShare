import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/device/device_provider.dart';
import 'package:clipshare/core/providers/tag/tag_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/features/history/providers/search_provider.dart';
import 'package:clipshare/features/history/widgets/filter/history_filter.dart';
import 'package:clipshare/features/history/widgets/history_list_view.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  static const tag = 'HistoryPage';

  var cancelExporting = false;
  var exporting = false;

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final realtimeList = ref.watch(historiesProvider);
    final searchNotifier = ref.read(searchProvider.notifier);

    //设备/标签变化时刷新筛选数据源
    ref.listen(deviceProvider, (_, __) => searchNotifier.loadCondition());
    ref.listen(tagProvider, (_, __) => searchNotifier.loadCondition());

    //搜索态展示搜索结果，否则展示实时历史流
    final list = search.searching ? search.list : realtimeList;

    return Column(
      children: [
        HistoryFilter(
          value: search.filter,
          devices: search.devices,
          tags: search.tags,
          sources: search.sources,
          showFillColor: isDesktop || !context.isCompactScreen,
          showSearchRow: !context.isCompactScreen,
          onChanged: searchNotifier.updateFilter,
          onSearch: searchNotifier.search,
          onExport: () => export(
            (lastId) {
              final db = ref.read(appDbProvider).requireValue;
              return db.historyDao.getHistoriesPageByFilter(
                ref.read(searchProvider).filter,
                true,
                lastId,
              );
            },
          ),
          onShowDetail: (detail) => ref.read(drawerProvider).controller.push(detail, null),
        ),
        Expanded(
          child: ClipListView(
            list: list,
            onExport: export,
            onLoadMoreData: () async {
              //todo 按当前 filter 分页加载更多
            },
            onRefresh: () async {
              //todo 下拉刷新
            },
          ),
        ),
      ],
    );
  }

  //region 导出
  Future export(FutureOr<List<History>> Function(int lastId) loadDataFunc) {
    var loadingController = LoadingProgressController();
    Completer<void> completer = Completer();
    unawaited(
      dialogManager.tips(
        context,
        text: TranslationKey.historyOutputTips.tr,
        actions: DialogActions(
          confirm: DialogAction(
            onPressed: () async {
              late final DialogController loadingDialog;
              loadingDialog = dialogManager.loading(
                context,
                loadingText: TranslationKey.exporting.tr,
                showCancel: true,
                controller: loadingController,
                onCancel: () {
                  cancelExporting = true;
                  exporting = false;
                },
              );
              try {
                final result = await export2Excel(loadingController, loadDataFunc);
                //关闭进度动画
                unawaited(loadingDialog.close());
                //手动取消
                if (!exporting) {
                  return;
                }
                if (!mounted) {
                  return;
                }
                if (result) {
                  snackbar.success(context, TranslationKey.outputSuccess.tr);
                } else {
                  snackbar.warn(context, TranslationKey.outputFailed.tr);
                }
              } catch (err, stack) {
                logger.error(tag, err, stack);
                //关闭进度动画
                unawaited(loadingDialog.close());
                if (!mounted) {
                  return;
                }
                await dialogManager.tips(
                  context,
                  title: TranslationKey.outputFailed.tr,
                  text: '$err. $stack',
                );
              } finally {
                //更新状态
                exporting = false;
                cancelExporting = false;
                completer.complete();
              }
            },
          ),
          cancel: const DialogAction(),
        ),
      ),
    );
    return completer.future;
  }

  ///导出为 excel
  Future<bool> export2Excel(LoadingProgressController loadingController, FutureOr<List<History>> Function(int lastId) loadDataFunc) async {
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
      var list = await loadDataFunc(lastId);
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

      if (item.isImage) {
        await Future.delayed(50.ms);
      }
    }
    loadingController.update(histories.length);
    logger.debug(tag, 'add2ExcelSheet finished');
    final List<int> bytes = workbook.saveAsStream();
    logger.debug(tag, 'workbook bytes: ${bytes.length}(${bytes.length.sizeStr})');
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
    //todo 国际化
    sheet.getRangeByName('A1').setText('时间');
    sheet.setColumnWidthInPixels(1, 150);
    sheet.getRangeByName('B1').setText('类型');
    sheet.getRangeByName('C1').setText('设备');
    sheet.getRangeByName('D1').setText('来源');
    sheet.getRangeByName('E1').setText('是否置顶');
    sheet.getRangeByName('F1').setText('内容');
    sheet.setColumnWidthInPixels(6, 570);
    sheet.getRangeByName('G1').setText('内容长度');
  }

  ///将历史数据添加到excel对象中，返回值为使用的行数
  Future<int> _add2ExcelSheet(Worksheet sheet, History history, int rowNum, Style timeStyle, Style vAlignStyle) async {
    if (rowNum <= 0) {
      throw ArgumentError('rowNum cannot less than 0');
    }
    final time = DateTime.parse(history.time);
    final type = HistoryContentType.parse(history.type);
    if (type == .file) {
      //文件同步跳过
      return 0;
    }
    late final String content;
    const maxCellLength = 32767;
    if (type == HistoryContentType.notification) {
      content = history.notificationContent ?? '[❌ Parse Data Failed]';
    } else {
      //转换 unicode 控制字符 \u0000 ~ \u001f，这些字符会导致 excel 打开失败
      //需要替换为 _x0000_ 这样的
      content = history.content.replaceAllMapped(
        RegExp(r'[\x00-\x1F]'),
        (match) => '_x${match.group(0)!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}_',
      );
    }
    var rowsOffset = 0;
    if (content.length > maxCellLength) {
      //单个单元格最多支持32767字符，否则会导致excel打开失败
      rowsOffset = (content.length / maxCellLength).ceil() - 1;
    }
    final deviceState = ref.read(deviceProvider).requireValue;
    final devName = deviceState.getName(history.devId);
    final size = history.sizeText;
    sheet.getRangeByName('A$rowNum:A${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = timeStyle
      ..setDateTime(time);
    sheet.getRangeByName('B$rowNum:B${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(type.label);
    sheet.getRangeByName('C$rowNum:C${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(devName);
    var source = '';
    //todo 来源名称解析待接入来源服务
    sheet.getRangeByName('D$rowNum:D${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(source);
    sheet.getRangeByName('E$rowNum:E${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = vAlignStyle
      ..setNumber(history.top ? 1 : 0);
    if (history.isImage) {
      final file = File(history.content);
      final cell = sheet.getRangeByName('F$rowNum');
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
        sheet.getRangeByName('F${rowNum + i}').setText(content.substring(start, end));
      }
    }
    sheet.getRangeByName('G$rowNum:G${rowNum + rowsOffset}')
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(size);
    return rowsOffset + 1;
  }

  //endregion
}
