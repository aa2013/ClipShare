import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/handlers/re-editor/lua_code_prompt.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/lua_code_edit_view.dart';
import 'package:clipshare/app/widgets/rule/script_test_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart';
import 'package:re_editor/re_editor.dart';

class LuaLibDetail extends StatefulWidget {
  final RuleLib lib;
  final void Function(RuleLib oldValue, RuleLib newValue) onSaveClicked;
  final ValueChanged<bool> onSaveStatusChanged;

  const LuaLibDetail({
    super.key,
    required this.lib,
    required this.onSaveClicked,
    required this.onSaveStatusChanged,
  });

  @override
  State<StatefulWidget> createState() => _LuaLibDetailState();
}

class _LuaLibDetailState extends State<LuaLibDetail> {
  static const tag = "LuaLibDetail";
  final appConfig = Get.find<ConfigService>();
  final codeEditor = CodeLineEditingController();
  final libNameEditor = TextEditingController();
  final displayNameEditor = TextEditingController();
  final libDao = Get.find<DbService>().ruleLibDao;
  var compileInfo = '';
  var compileSuccess = false;
  var result = '';
  var shouldSave = false;
  var luaRuntime = LuaRuntime();

  RuleLib toNewLib() {
    return RuleLib(
      libName: libNameEditor.text,
      displayName: displayNameEditor.text,
      language: widget.lib.language,
      source: codeEditor.text,
      version: widget.lib.version,
      isNewData: widget.lib.isNewData,
    );
  }

  Future<String?> validate(RuleLib lib) async {
    if (!compileSuccess) {
      return TranslationKey.ruleLibDetailSyntaxError.tr;
    }
    if (lib.displayName.isNullOrEmpty) {
      return TranslationKey.ruleLibDetailDisplayNameRequired.tr;
    }
    if (lib.libName.isNullOrEmpty) {
      return TranslationKey.ruleLibDetailLibNameRequired.tr;
    }
    if (lib.isNewData) {
      final dbLib = await libDao.getByLibName(lib.libName);
      if (dbLib != null) {
        return TranslationKey.ruleLibDetailLibNameDuplicated.tr;
      }
    }
    if (lib.source.trim().isNullOrEmpty) {
      return TranslationKey.ruleLibDetailContentRequired.tr;
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
  void didUpdateWidget(covariant LuaLibDetail oldWidget) {
    updateState();
    super.didUpdateWidget(oldWidget);
  }

  void updateState() {
    compileInfo = '';
    compileSuccess = false;
    result = '';
    if (widget.lib.source.trim().isNullOrEmpty) {
      codeEditor.text = "return {}";
    } else {
      codeEditor.text = widget.lib.source;
    }
    libNameEditor.text = widget.lib.libName;
    displayNameEditor.text = widget.lib.displayName;
    shouldSave = widget.lib.version <= 0;
    luaRuntime.dispose();
    luaRuntime = LuaRuntime();
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
    final result = luaRuntime.run(
      Constants.luaLibCompileWrapper.replaceAll(
        r"{{code}}",
        code,
      ),
    );
    Log.debug(tag, "lua lib compile result: $result");
    if (result.isNullOrEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            "message": TranslationKey.ruleLibCompileReturnTableRequired.tr,
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
          this.result = result.replaceFirst("table:", "");
        });
      });
    }
  }

  @override
  void dispose() {
    codeEditor.removeListener(onCodeChanged);
    codeEditor.dispose();
    libNameEditor.dispose();
    displayNameEditor.dispose();
    super.dispose();
  }

  Future<void> saveData(RuleLib newLib) async {
    final result = await validate(newLib);
    if (result != null) {
      Global.showSnackBarWarn(text: result, context: context);
      return;
    }
    widget.onSaveClicked(widget.lib, newLib);
  }

  @override
  Widget build(BuildContext context) {
    final newLib = toNewLib();
    shouldSave = newLib != widget.lib;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSaveStatusChanged(shouldSave);
    });
    final body = Padding(
      padding: 5.insetAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                TranslationKey.ruleLibDetailDisplayNameLabel.tr,
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: displayNameEditor,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: TranslationKey.ruleLibDetailDisplayNameHint.tr,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                TranslationKey.ruleLibDetailLibNameLabel.tr,
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Tooltip(
            message: widget.lib.isNewData
                ? TranslationKey.ruleLibDetailLibNameImmutableTooltip.tr
                : TranslationKey.readonly.tr,
            child: TextField(
              controller: libNameEditor,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: TranslationKey.ruleLibDetailLibNameHint.tr,
              ),
              readOnly: !widget.lib.isNewData,
              maxLines: 1,
            ),
          ),

          const SizedBox(height: 5),
          Expanded(
            child: LuaCodeEditView(
              controller: codeEditor,
              relatedPrompts: luaBuiltinRelatedPrompts,
              directPrompts: luaBuiltinDirectPrompts,
              onSaveShortcutTriggered: () {
                saveData(toNewLib());
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
                  onPressed: shouldSave ? () => saveData(toNewLib()) : null,
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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(TranslationKey.ruleLibDetailPageTitle.tr),
        ),
        body: PopScope(
          canPop: !shouldSave,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) {
              return;
            }
            Global.showTipsDialog(
              context: context,
              text: TranslationKey.unsavedTips.tr,
              showCancel: true,
              onOk: () {
                widget.onSaveStatusChanged.call(false);
                //退出页面
                Navigator.of(context).pop();
              },
            );
          },
          child: body,
        ),
      );
    } else {
      return body;
    }
  }
}
