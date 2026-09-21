import 'dart:convert';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/rules/rules_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/rules/widgets/lua_code_edit_view.dart';
import 'package:clipshare/features/rules/widgets/script_test_panel.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';

/// 脚本模块详情入口页。
///
/// 自身只负责从 [rulesExecutorProvider] 取选中的脚本模块；实际编辑表单交由
/// [_ScriptModuleDetailView] 承载，并用模块名作 key，切换模块时重建表单状态。
class ScriptModuleDetail extends ConsumerWidget {
  const ScriptModuleDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(
      rulesExecutorProvider.select((asyncValue) => asyncValue.value?.selectedLuaModuleItem),
    );
    if (module == null) {
      return const EmptyContent();
    }
    return _ScriptModuleDetailView(key: ValueKey(module.moduleName), module: module);
  }
}

class _ScriptModuleDetailView extends ConsumerStatefulWidget {
  final ScriptModule module;

  const _ScriptModuleDetailView({
    super.key,
    required this.module,
  });

  @override
  ConsumerState<_ScriptModuleDetailView> createState() => _ScriptModuleDetailState();
}

class _ScriptModuleDetailState extends ConsumerState<_ScriptModuleDetailView> {
  static const tag = 'ScriptModuleDetail';
  final codeEditor = CodeLineEditingController();
  final moduleNameEditor = TextEditingController();
  final displayNameEditor = TextEditingController();
  ScriptModuleDao get scriptModuleDao => ref.read(appDbProvider).requireValue.scriptModuleDao;
  RulesExecutorNotifier get rulesExecutor => ref.read(rulesExecutorProvider.notifier);
  var compileInfo = '';
  var compileSuccess = false;
  var result = '';
  var shouldSave = false;

  ScriptModule toNewModule() {
    final module = ScriptModule(
      moduleName: moduleNameEditor.text,
      displayName: displayNameEditor.text,
      language: widget.module.language,
      source: codeEditor.text,
      version: widget.module.version,
    );
    module.isNewData = widget.module.isNewData;
    return module;
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
      return '${TranslationKey.scriptModuleDetailModuleNameLabel.tr} ${TranslationKey.scriptModuleDetailNameInvalid.tr}';
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

  void updateState() {
    compileInfo = '';
    compileSuccess = false;
    result = '';
    if (widget.module.source.trim().isNullOrEmpty) {
      codeEditor.text = 'return {}';
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
            'message': TranslationKey.ruleCompileCodeNotFound.tr,
          });
          compileSuccess = false;
          this.result = '';
        });
      });
      return;
    }
    final result = rulesExecutor.compileModule(code);
    logger.debug(tag, 'lua lib compile result: $result');
    if (result.isNullOrEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            'message': TranslationKey.scriptModuleCompileReturnTableRequired.tr,
          });
          compileSuccess = false;
          this.result = '';
        });
      });
    } else if (!result.startsWithIgnoreCase('table:')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
            'message': result,
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
          var runResult = result.replaceFirst('table:', '');
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
      if (context.mounted) {
        snackbar.warn(context, result);
      }
      return;
    }
    final success = await rulesExecutor.saveScriptModule(widget.module, newLib);
    if (!mounted) {
      return;
    }
    if (!success) {
      snackbar.error(context, TranslationKey.saveFailed.tr);
      return;
    }
    snackbar.success(context, TranslationKey.saveSuccess.tr);
  }

  @override
  Widget build(BuildContext context) {
    final newLib = toNewModule();
    shouldSave = newLib != widget.module;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      rulesExecutor.updateActiveItemChanged(shouldSave);
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
            decoration: context.noneBorderInputDecoration.copyWith(
              isDense: true,
              hintText: TranslationKey.scriptModuleDetailDisplayNameHint.tr,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Text(
            '${TranslationKey.scriptModuleDetailModuleNameLabel.tr}: ',
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 5),
          Tooltip(
            message: widget.module.isNewData
                ? TranslationKey.scriptModuleDetailModuleNameImmutableTooltip.tr
                : TranslationKey.readonly.tr,
            child: TextField(
              controller: moduleNameEditor,
              decoration: context.noneBorderInputDecoration.copyWith(
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
    if (context.isCompactScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationKey.scriptModuleDetailPageTitle.tr),
        ),
        body: PopScope(
          canPop: !shouldSave,
          onPopInvokedWithResult: (bool didPop, dynamic result) {

            if (didPop) {
              rulesExecutor.updateSelectedScriptModule(null);
              return;
            }
            dialogManager.tips(
              context,
              text: TranslationKey.unsavedTips.tr,
              actions: DialogActions(
                cancel: const DialogAction(),
                confirm: DialogAction(
                  onPressed: (){
                    rulesExecutor.updateActiveItemChanged(false);
                    rulesExecutor.updateSelectedScriptModule(null);
                    //退出页面
                    context.pop();
                  }
                )
              ),
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
