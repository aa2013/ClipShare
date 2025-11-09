import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/my_code_keyword_prompt.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/sql.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DbEditorController extends GetxController {
  static const logTag = "DbEditorController";
  final dbService = Get.find<DbService>();
  final keywordPrompts = [
    ...tables.map((t) => MyCodeKeywordPrompt(word: t.toString())),
    ...views.map((t) => MyCodeKeywordPrompt(word: t.toString())),
    MyCodeKeywordPrompt(word: 'limit'),
  ].toList(growable: false);
  final tableInsets = const EdgeInsets.only(right: 2, bottom: 2);
  final CodeLineEditingController editor = CodeLineEditingController();
  final _tableColumns = Rx<List<DataColumn>>([]);
  final _tableRows = Rx<List<DataRow>>([]);
  final _loading = false.obs;
  final showLimitTips = true.obs;

  bool get loading => _loading.value;

  List<DataColumn> get columns => _tableColumns.value;

  List<DataRow> get rows => _tableRows.value;

  @override
  void onInit() {
    super.onInit();
    langSql.keywords["keyword"].add("limit");
  }

  Future<void> exec() async {
    try {
      _loading.value = true;
      // 清空已有表格
      _tableColumns.value = [];
      _tableRows.value = [];
      List<Map<String, Object?>> list = await dbService.dbExecutor.rawQuery(editor.text);

      if (list.isEmpty) {
        return;
      }
      List<DataRow> rows = [];
      List<DataColumn> columns = [const DataColumn(label: Text("#"))];
      columns.addAll(list.first.keys.map((name) => DataColumn(label: Text(name))));
      // 构建内容行
      for (var i = 1; i <= list.length; i++) {
        final rowMap = list[i - 1];
        final cells = List<DataCell>.empty(growable: true);
        cells.add(DataCell(Text(i.toString())));
        cells.addAll(
          rowMap.values.map(
            (value) => DataCell(
              GestureDetector(
                child: Text(value?.toString().substringMinLen(0, 50) ?? ''),
                onTap: () {
                  final text = value?.toString() ?? '';
                  Global.showTipsDialog(
                    context: Get.context!,
                    title: TranslationKey.content.tr,
                    text: text,
                    showCancel: true,
                    okText: TranslationKey.copyContent.tr,
                    cancelText: TranslationKey.close.tr,
                    onOk: () async {
                      await clipboardManager.copy(ClipboardContentType.text, text);
                      Global.showSnackBarSuc(text: TranslationKey.copySuccess.tr);
                    },
                  );
                },
              ),
            ),
          ),
        );
        rows.add(
          DataRow(cells: cells),
        );
      }

      _tableColumns.value = columns;
      _tableRows.value = rows;
    } catch (err, stack) {
      Global.showTipsDialog(
        context: Get.context!,
        title: TranslationKey.execFailed.tr,
        text: "$err\n$stack",
      );
      Log.error(logTag, err, stack);
    } finally {
      _loading.value = false;
    }
  }
}
