import 'package:clipshare/core/constants/theme_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/features/db_editor/providers/db_editor_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare/shared/widgets/re-editor/code_edit_view.dart';
import 'package:clipshare/theme/re-editor/highlight_sqlite.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

/// 数据库查询编辑页：表名快捷输入、SQL 编辑执行与结果表格展示。
class DbEditorPage extends ConsumerStatefulWidget {
  const DbEditorPage({super.key});

  @override
  ConsumerState<DbEditorPage> createState() => _DbEditorPageState();
}

class _DbEditorPageState extends ConsumerState<DbEditorPage> {
  static const tag = 'DbEditorPage';

  /// 结果单元格预览文本最大长度，点击单元格可查看并复制全文
  static const cellPreviewMaxLen = 50;

  /// SQL 编辑区高度
  static const editorHeight = 150.0;

  /// 执行行内小图标尺寸
  static const execRowIconSize = 18.0;

  /// 触发执行前确认提示的 SQL 关键字
  static const sqlKeywordSelect = 'select';
  static const sqlKeywordLimit = 'limit';

  /// 各区块之间的统一间距
  static const rowGap = SizedBox(height: 5);

  /// 表名 chip 的外边距
  static const tableChipInsets = EdgeInsets.only(right: 2, bottom: 2);

  final editor = CodeLineEditingController();

  @override
  void initState() {
    super.initState();
    _restoreLastSql();
  }

  /// 恢复上次退出前编辑的 SQL 内容。
  Future<void> _restoreLastSql() async {
    final prefs = await ref.read(preferenceSettingsProvider.future);
    if (!mounted || editor.text.isNotEmpty) {
      return;
    }
    editor.text = prefs.lastSqlEditContent;
  }

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  /// 执行 SQL；失败时弹出错误详情弹窗。
  Future<void> _exec() async {
    final notifier = ref.read(dbEditorProvider.notifier);
    try {
      await notifier.exec(editor.text);
    } catch (err, stack) {
      logger.error(tag, err, stack);
      if (!mounted) {
        return;
      }
      await dialogManager.tips(
        context,
        title: TranslationKey.execFailed.tr,
        text: '$err\n$stack',
      );
    }
  }

  /// 执行按钮点击：开启 limit 检查时，无 limit 的 select 语句需先确认。
  void _onExecPressed() {
    final state = ref.read(dbEditorProvider);
    if (state.loading) {
      return;
    }
    final sql = editor.text.toLowerCase();
    final showLimitTips = state.showLimitTips;
    if (showLimitTips && sql.contains(sqlKeywordSelect) && !sql.contains(sqlKeywordLimit)) {
      dialogManager.tips(
        context,
        text: TranslationKey.execSQLNoLimitTips.tr,
        actions: DialogActions(
          cancel: const DialogAction(),
          confirm: DialogAction(onPressed: _exec),
        ),
      );
      return;
    }
    _exec();
  }

  /// 点击表名 chip，将表名追加到 SQL 编辑区末尾。
  void _onTableChipClicked(String name) {
    editor.text += name;
  }

  /// 弹出单元格全文弹窗，支持复制内容。
  void _showCellDetail(String text) {
    dialogManager.tips(
      context,
      title: TranslationKey.content.tr,
      text: text,
      selectable: true,
      actions: DialogActions(
        cancel: DialogAction(text: TranslationKey.close.tr),
        confirm: DialogAction(
          text: TranslationKey.copyContent.tr,
          onPressed: () async {
            await clipboardManager.copy(ClipboardContentType.text, text);
            if (!mounted) {
              return;
            }
            snackbar.success(context, TranslationKey.copySuccess.tr);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dbEditorProvider);
    final db = ref.read(appDbProvider).requireValue;
    final tableNames = db.allTables
        .map((table) => table.actualTableName)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationKey.editDb.tr),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rowGap,
              _buildTablesRow(tableNames),
              rowGap,
              _buildExecRow(state),
              rowGap,
              CodeEditView(
                controller: editor,
                language: langSqliteHighlight,
                codeTheme: codeSQLTheme,
                hintText: TranslationKey.enterSQLHere.tr,
                keywordPrompts: _buildKeywordPrompts(tableNames),
                height: editorHeight,
              ),
              rowGap,
              Text('${TranslationKey.result.tr}: '),
              rowGap,
              Expanded(child: _buildResultArea(state)),
            ],
          ),
        ),
      ),
    );
  }

  /// 表名快捷输入行：点击 chip 追加表名到编辑区。
  Widget _buildTablesRow(List<String> tableNames) {
    return Row(
      children: [
        Text(TranslationKey.optionalTables.tr),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...tableNames.map(
                  (name) => Container(
                    margin: tableChipInsets,
                    child: RoundedChip(
                      label: Text(name),
                      onPressed: () => _onTableChipClicked(name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 执行行：执行按钮与 limit 检查开关。
  Widget _buildExecRow(DbEditorState state) {
    final notifier = ref.read(dbEditorProvider.notifier);
    return Row(
      children: [
        Text(TranslationKey.execSQL.tr),
        const SizedBox(width: 5),
        Tooltip(
          message: TranslationKey.execSQL.tr,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _onExecPressed,
            icon: state.loading
                ? const Loading(width: execRowIconSize)
                : const Icon(
                    Icons.play_arrow,
                    color: Colors.orange,
                  ),
          ),
        ),
        Tooltip(
          message: TranslationKey.toggleSQLLimitCheck.tr,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: notifier.toggleLimitCheck,
            icon: Icon(
              Icons.not_interested,
              size: execRowIconSize,
              color: state.showLimitTips ? Colors.orange : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  /// 由表名生成 SQL 自动补全提示词。
  List<CaseInsensitiveKeywordPrompt> _buildKeywordPrompts(List<String> tableNames) {
    return tableNames
        .map((name) => CaseInsensitiveKeywordPrompt(word: name))
        .toList(growable: false);
  }

  /// 结果区三态：加载中/结果表格/空内容。
  Widget _buildResultArea(DbEditorState state) {
    if (state.loading) {
      return const Loading(width: 40);
    }
    if (state.results.isNotEmpty) {
      return SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _buildResultColumns(state.results),
            rows: _buildResultRows(state.results),
          ),
        ),
      );
    }
    return const EmptyContent();
  }

  /// 结果表列：首列为行号，其余按首行数据的键名生成。
  List<DataColumn> _buildResultColumns(List<Map<String, Object?>> results) {
    final columns = [const DataColumn(label: Text('#'))];
    final keys = results.first.keys;
    columns.addAll(keys.map((name) => DataColumn(label: Text(name))));
    return columns;
  }

  /// 结果表行：行号单元格 + 数据单元格（预览截断，点击查看全文）。
  List<DataRow> _buildResultRows(List<Map<String, Object?>> results) {
    final rows = <DataRow>[];
    for (var i = 1; i <= results.length; i++) {
      final rowMap = results[i - 1];
      final cells = <DataCell>[DataCell(Text(i.toString()))];
      cells.addAll(rowMap.values.map(_buildResultCell));
      rows.add(DataRow(cells: cells));
    }
    return rows;
  }

  /// 单个结果单元格：文本超过 [cellPreviewMaxLen] 时截断展示，点击弹窗查看全文。
  DataCell _buildResultCell(Object? value) {
    final text = value?.toString() ?? '';
    return DataCell(
      GestureDetector(
        child: Text(text.substringMinLen(0, cellPreviewMaxLen)),
        onTap: () => _showCellDetail(text),
      ),
    );
  }
}
