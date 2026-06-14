import 'dart:convert';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:clipshare/app/handlers/re-editor/lua_code_prompt.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/lua_code_edit_view.dart';
import 'package:clipshare/app/widgets/rule/script_test_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart';
import 'package:re_editor/re_editor.dart';

class ScriptModuleDetail extends StatefulWidget {
  final RulesController controller;
  final ScriptModule module;
  final void Function(ScriptModule oldValue, ScriptModule newValue) onSaveClicked;
  final ValueChanged<bool> onSaveStatusChanged;

  const ScriptModuleDetail({
    super.key,
    required this.module,
    required this.controller,
    required this.onSaveClicked,
    required this.onSaveStatusChanged,
  });

  @override
  State<StatefulWidget> createState() => _ScriptModuleDetailState();
}

class _ScriptModuleDetailState extends State<ScriptModuleDetail> {
  static const tag = "ScriptModuleDetail";
  final appConfig = Get.find<ConfigService>();
  final codeEditor = CodeLineEditingController();
  final moduleNameEditor = TextEditingController();
  final displayNameEditor = TextEditingController();
  final scriptModuleDao = Get.find<DbService>().scriptModuleDao;
  var compileInfo = '';
  var compileSuccess = false;
  var result = '';
  var shouldSave = false;

  ScriptModule toNewModule() {
    return ScriptModule(
      moduleName: moduleNameEditor.text,
      displayName: displayNameEditor.text,
      language: widget.module.language,
      source: codeEditor.text,
      version: widget.module.version,
      isNewData: widget.module.isNewData,
    );
  }

  Future<String?> validate(ScriptModule lib) async {
    if (!compileSuccess) {
      return TranslationKey.ruleModulesDetailSyntaxError.tr;
    }
    if (lib.displayName.isNullOrEmpty) {
      return TranslationKey.scriptModulesDetailDisplayNameRequired.tr;
    }
    if (lib.moduleName.isNullOrEmpty) {
      return TranslationKey.scriptModulesDetailModuleNameRequired.tr;
    }
    if(!lib.moduleName.isValidVariablePart){
      return "${TranslationKey.scriptModuleDetailModuleNameLabel.tr} ${TranslationKey.scriptModuleDetailNameInvalid.tr}";
    }
    if (lib.isNewData) {
      final dbLib = await scriptModuleDao.getByName(lib.moduleName);
      if (dbLib != null) {
        return TranslationKey.scriptModulesDetailModuleNameDuplicated.tr;
      }
    }
    if (lib.source.trim().isNullOrEmpty) {
      return TranslationKey.scriptModuleDetailContentRequired.tr;
    }
    return null;
  }

  @override
  void initState() {
    updateState();
    codeEditor.addListener(onCodeChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ScriptModuleDetail oldWidget) {
    updateState();
    super.didUpdateWidget(oldWidget);
  }

  void updateState() {
    compileInfo = '';
    compileSuccess = false;
    result = '';
    if (widget.module.source.trim().isNullOrEmpty) {
      codeEditor.text = "return {}";
    } else {
      codeEditor.text = widget.module.source;
    }
    moduleNameEditor.text = widget.module.moduleName;
    displayNameEditor.text = widget.module.displayName;
    shouldSave = widget.module.version <= 0;
  }

  void onCodeChanged() {
    final code = codeEditor.text;
    if (code.isNullOrEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            "message": TranslationKey.ruleCompileCodeNotFound.tr,
          });
          compileSuccess = false;
          this.result = '';
        });
      });
      return;
    }
    final result = widget.controller.compileModule(code);
    logger.debug(tag, "lua lib compile result: $result");
    if (result.isNullOrEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            "message": TranslationKey.scriptModuleCompileReturnTableRequired.tr,
          });
          compileSuccess = false;
          this.result = '';
        });
      });
    } else if (!result.startsWithIgnoreCase('table:')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            "message": result,
          });
          compileSuccess = false;
          this.result = '';
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileSuccess.tr;
          compileSuccess = true;
          var runResult = result.replaceFirst("table:", "");
          try {
            var data = jsonDecode(runResult);
            const encoder = JsonEncoder.withIndent('  '); // 2个空格缩进
            runResult = encoder.convert(data);
          } catch (_) {
            //ignored
          } finally {
            this.result = runResult;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    codeEditor.removeListener(onCodeChanged);
    codeEditor.dispose();
    moduleNameEditor.dispose();
    displayNameEditor.dispose();
    super.dispose();
  }

  Future<void> saveData(ScriptModule newLib) async {
    final result = await validate(newLib);
    if (result != null) {
      Global.showSnackBarWarn(text: result, context: context);
      return;
    }
    widget.onSaveClicked(widget.module, newLib);
  }

  @override
  Widget build(BuildContext context) {
    final newLib = toNewModule();
    shouldSave = newLib != widget.module;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSaveStatusChanged(shouldSave);
    });
    final body = Padding(
      padding: 5.insetAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationKey.scriptModuleDetailDisplayNameLabel.tr,
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: displayNameEditor,
            decoration: noneBorderInputDecoration.copyWith(
              isDense: true,
              hintText: TranslationKey.scriptModuleDetailDisplayNameHint.tr,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Text(
            "${TranslationKey.scriptModuleDetailModuleNameLabel.tr}: ",
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 5),
          Tooltip(
            message: widget.module.isNewData
                ? TranslationKey.scriptModuleDetailModuleNameImmutableTooltip.tr
                : TranslationKey.readonly.tr,
            child: TextField(
              controller: moduleNameEditor,
              decoration: noneBorderInputDecoration.copyWith(
                isDense: true,
                hintText: TranslationKey.scriptModuleDetailModuleNameHint.tr,
                errorText: moduleNameEditor.text.isValidVariablePart
                    ? null
                    : TranslationKey.scriptModuleDetailNameInvalid.tr,
              ),
              readOnly: !widget.module.isNewData,
              maxLines: 1,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9_]'),
                ),
              ],
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 5),
          Expanded(
            child: LuaCodeEditView(
              controller: codeEditor,
              onSaveShortcutTriggered: () {
                saveData(toNewModule());
              },
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 150,
            child: ScriptTestPanel(
              showCompileInfo: true,
              showOutputsInfo: false,
              compileInfo: compileInfo,
              initialIndex: 0,
              toolWidget: (context) {
                return IconButton(
                  onPressed: shouldSave ? () => saveData(toNewModule()) : null,
                  tooltip: TranslationKey.save.tr,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.save,
                    color: shouldSave ? Colors.blueGrey : Colors.grey,
                  ),
                );
              },
              resultPanelBuilder: (context) {
                return SelectableText(result);
              },
            ),
          ),
        ],
      ),
    );
    if (appConfig.isSmallScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationKey.scriptModuleDetailPageTitle.tr),
        ),
        body: PopScope(
          canPop: !shouldSave,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            final ruleController = Get.find<RulesController>();
            if (didPop) {
              ruleController.selectedLuaModuleItem.value = null;
              return;
            }
            Global.showTipsDialog(
              context: context,
              text: TranslationKey.unsavedTips.tr,
              showCancel: true,
              onOk: () {
                widget.onSaveStatusChanged.call(false);
                ruleController.selectedLuaModuleItem.value = null;
                //退出页面
                Navigator.of(context).pop();
              },
            );
          },
          child: SafeArea(child: body),
        ),
      );
    } else {
      return body;
    }
  }
}
