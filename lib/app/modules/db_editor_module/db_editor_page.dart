import 'dart:ui';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/re-editor/code_autocomplete_prompts_builder.dart';
import 'package:clipshare/app/handlers/re-editor/default_code_autocomplete_listview.dart';
import 'package:clipshare/app/modules/views/code_edit_view.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/largeText/find.dart';
import 'package:clipshare/app/widgets/largeText/menu.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clipshare/app/modules/db_editor_module/db_editor_controller.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DbEditorPage extends GetView<DbEditorController> {
  Widget renderCodeEditor(BuildContext context) {
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        return DefaultCodeAutocompleteListView(
          notifier: notifier,
          onSelected: onSelected,
        );
      },
      promptsBuilder: MyCodeAutocompletePromptsBuilder(
        language: langSql,
        keywordPrompts: controller.keywordPrompts,
      ),
      child: CodeEditor(
        controller: controller.editor,
        wordWrap: true,
        hint: TranslationKey.enterSQLHere.tr,
        autofocus: true,
        indicatorBuilder: (context, editingController, chunkController, notifier) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              ),
              DefaultCodeChunkIndicator(
                width: 20,
                controller: chunkController,
                notifier: notifier,
              ),
            ],
          );
        },
        findBuilder: (context, controller, readOnly) => CodeFindPanelView(controller: controller, readOnly: readOnly),
        toolbarController: const ContextMenuControllerImpl(),
        sperator: Container(width: 1, color: const Color(0xADADAFB6)),
        style: CodeEditorStyle(
          fontSize: 18,
          hintTextColor: Colors.grey,
          codeTheme: CodeHighlightTheme(
            languages: {'sql': CodeHighlightThemeMode(mode: langSql)},
            theme: atomOneLightTheme,
          ),
        ),
      ),
    );
  }

  void onTableChipClicked(String name) {
    controller.editor.text += name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationKey.editDb.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Text(TranslationKey.optionalTables.tr),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...tables.map(
                          (t) => Container(
                            margin: controller.tableInsets,
                            child: RoundedChip(label: Text(t.toString()), onPressed: () => onTableChipClicked(t.toString())),
                          ),
                        ),
                        ...views.map(
                          (t) => Container(
                            margin: controller.tableInsets,
                            child: RoundedChip(
                              label: Text(t.toString()),
                              onPressed: () => onTableChipClicked(t.toString()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(TranslationKey.execSQL.tr),
                const SizedBox(width: 5),
                Tooltip(
                  message: TranslationKey.execSQL.tr,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (controller.loading) return;
                      final text = controller.editor.text.toLowerCase();
                      if (controller.showLimitTips.value && text.contains("select") && !text.contains("limit")) {
                        Global.showTipsDialog(
                          context: context,
                          text: TranslationKey.execSQLNoLimitTips.tr,
                          showCancel: true,
                          onOk: () {
                            controller.exec();
                          },
                        );
                        return;
                      }
                      controller.exec();
                    },
                    icon: Obx(
                      () => Visibility(
                        visible: controller.loading,
                        replacement: const Icon(
                          Icons.play_arrow,
                          color: Colors.orange,
                        ),
                        child: const Loading(
                          width: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: TranslationKey.toggleSQLLimitCheck.tr,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      controller.showLimitTips.value = !controller.showLimitTips.value;
                    },
                    icon: Obx(
                      () => Icon(
                        Icons.not_interested,
                        size: 18,
                        color: controller.showLimitTips.value ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            CodeEditView(
              controller: controller.editor,
              language: langSql,
              codeTheme: Constants.codeSQLTheme,
              hintText: TranslationKey.enterSQLHere.tr,
              keywordPrompts: controller.keywordPrompts,
              height: 150,
            ),
            const SizedBox(height: 5),
            Text("${TranslationKey.result.tr}: "),
            const SizedBox(height: 5),
            Expanded(
              child: Obx(
                () {
                  if (controller.loading) {
                    return const Loading(
                      width: 40,
                    );
                  }
                  if (controller.columns.isNotEmpty) {
                    return SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: controller.columns,
                          rows: controller.rows,
                        ),
                      ),
                    );
                  }
                  return EmptyContent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
