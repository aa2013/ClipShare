import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/device/device_provider.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/rules/lua/template.dart';
import 'package:clipshare/core/rules/rules_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/app_selection/app_selection_entry.dart';
import 'package:clipshare/features/rules/widgets/lua_code_edit_view.dart';
import 'package:clipshare/features/rules/widgets/script_edit_test_view.dart';
import 'package:clipshare/features/rules/widgets/script_test_panel.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/enums/support_platform.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/list_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/rule/rule_exec_params.dart';
import 'package:clipshare/shared/models/rule/rule_exec_result.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/models/rule/rule_regex_content.dart';
import 'package:clipshare/shared/models/rule/rule_script_content.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:clipshare/shared/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/shared/widgets/dialogs/text_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';

///region 分段控件统一配色（触发时机/规则模式/规则类型三处复用）
const _segmentSelectedBackgroundColor = Colors.blueGrey;
const _segmentSelectedColor = Colors.white;
const _segmentLightBackgroundColor = Color(0xffdde1e3);
const _segmentDarkBackgroundColor = Color(0xff2e3b42);
///endregion

/// 规则详情入口页。
///
/// 自身只负责从 [rulesExecutorProvider] 取选中的规则；实际编辑表单交由
/// [_RuleDetailView] 承载，并用规则 id 作 key，切换规则时重建表单状态。
class RuleDetail extends ConsumerWidget {
  const RuleDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(
      rulesExecutorProvider.select((asyncValue) => asyncValue.value?.selectedRuleItem),
    );
    if (rule == null) {
      return const EmptyContent();
    }
    return _RuleDetailView(key: ValueKey(rule.id), rule: rule);
  }
}

class _RuleDetailView extends ConsumerStatefulWidget {
  final RuleItem rule;

  const _RuleDetailView({
    super.key,
    required this.rule,
  });

  @override
  ConsumerState<_RuleDetailView> createState() => _RuleDetailViewState();
}

class _RuleDetailViewState extends ConsumerState<_RuleDetailView> {
  final GlobalKey codeEditorKey = GlobalKey();
  var shouldSave = false;
  static const tag = 'RuleDetail';
  var isScriptFullScreen = false;
  var autoWrapText = false;

  static const int regexTextFieldMaxLines = 4;
  static const contentMargin = 5;
  List<AppInfo> selectedAppInfos = [];
  final topContentKey = GlobalKey();

  /// 查看页索引与规则类型合一：切换分段即修改规则类型
  int get tabIndex => ruleContentType == RuleContentType.regex ? 0 : 1;

  RulesExecutorNotifier get rulesExecutor => ref.read(rulesExecutorProvider.notifier);

  Set<SupportPlatForm> selectedPlatforms = {};
  Set<String> selectedSourceIds = {};
  RuleTrigger selectedTrigger = RuleTrigger.onCopy;
  var ruleContentType = RuleContentType.regex;
  WhiteBlackMode whiteBlackMode = WhiteBlackMode.defaultMode;
  var isAllowExtractData = false;
  var isPreventSync = false;
  var isFinalRule = false;
  var isAllowPostAddTags = false;
  var postTags = <String>{};
  final regexTextController = TextEditingController();
  final extractTextController = TextEditingController();
  final ruleNameTextController = TextEditingController();
  final testParamsContentController = TextEditingController();
  final codeController = CodeLineEditingController();
  RuleExecResult? testResult;

  RuleItem? originRule;

  RuleItem? toRule() {
    if (originRule == null) {
      return null;
    }
    var origin = originRule!;
    var isFinal = isFinalRule;
    if (ruleContentType == RuleContentType.regex) {
      if (whiteBlackMode == WhiteBlackMode.black) {
        isFinal = true;
      } else if (whiteBlackMode == WhiteBlackMode.white) {
        isFinal = false;
      }
    }
    return RuleItem(
      id: origin.id,
      version: origin.version,
      name: ruleNameTextController.text,
      platforms: {...selectedPlatforms},
      sources: {...selectedSourceIds},
      trigger: selectedTrigger,
      type: ruleContentType,
      regex: RuleRegexContent(
        mainRegex: regexTextController.text,
        allowExtractData: isAllowExtractData,
        extractRegex: extractTextController.text,
        allowAddTag: isAllowPostAddTags,
        tags: {...postTags},
        preventSync: isPreventSync,
        isFinal: isFinal,
        mode: whiteBlackMode,
      ),
      script: RuleScriptContent(
        language: RuleScriptLanguage.lua,
        content: codeController.text,
      ),
      enabled: origin.enabled,
      order: origin.order,
      isNewData: origin.isNewData,
    );
  }

  void updateStateData(RuleItem rule) {
    originRule = rule.copy();
    selectedPlatforms = rule.platforms;
    selectedSourceIds = rule.sources;
    selectedTrigger = rule.trigger;
    ruleContentType = rule.type;
    isAllowExtractData = rule.regex.allowExtractData;
    isPreventSync = rule.regex.preventSync;
    isFinalRule = rule.regex.isFinal;
    isAllowPostAddTags = rule.regex.allowAddTag;
    postTags = rule.regex.tags;
    regexTextController.text = rule.regex.mainRegex;
    extractTextController.text = rule.regex.extractRegex;
    ruleNameTextController.text = rule.name;
    isScriptFullScreen = false;
    whiteBlackMode = rule.regex.mode;
    if (rule.script.content.trim().isNullOrEmpty) {
      codeController.text = luaTemplateRule;
    } else {
      codeController.text = rule.script.content;
    }
    selectedAppInfos = selectedSourceIds.map((appId) {
      // 优先取来源缓存中的展示信息，缺失时用 appId 兜底占位
      final sourceState = ref.read(clipboardSourceProvider).value;
      final appInfo = sourceState?.getAppInfoByAppId(appId);
      if (appInfo != null) {
        return appInfo;
      }
      return AppInfo(id: 0, appId: appId, devId: '', name: appId, iconB64: '');
    }).toList();
  }

  @override
  void initState() {
    updateStateData(widget.rule);
    regexTextController.addListener(updateState);
    extractTextController.addListener(updateState);
    ruleNameTextController.addListener(updateState);
    codeController.addListener(updateState);
    super.initState();
  }

  void updateState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    regexTextController.removeListener(updateState);
    extractTextController.removeListener(updateState);
    ruleNameTextController.removeListener(updateState);
    codeController.removeListener(updateState);
    codeController.dispose();
    regexTextController.dispose();
    extractTextController.dispose();
    ruleNameTextController.dispose();
    testParamsContentController.dispose();
    super.dispose();
  }

  Widget buildRuleInfo(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ///region 名称
        Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailNameLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
        TextField(
          controller: ruleNameTextController,
          decoration: context.noneBorderInputDecoration.copyWith(
            contentPadding: 12.insetAll,
            hintText: TranslationKey.ruleDetailNameHint.tr,
          ),
        ),

        ///endregion

        ///region 平台
        Row(
          children: [
            const Icon(
              Icons.apps,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailPlatformLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var pf in SupportPlatForm.values)
              Container(
                margin: 5.insetLT,
                child: RoundedChip(
                  showCheckmark: false,
                  backgroundColor: isDark ? theme.cardTheme.color ?? theme.colorScheme.surfaceBright : null,
                  selectedColor: isDark ? theme.colorScheme.primary.withValues(alpha: 0.22) : null,
                  labelStyle: isDark ? TextStyle(color: selectedPlatforms.contains(pf) ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.72)) : null,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  avatar: Icon(pf.icon),
                  label: Text(pf.toString()),
                  selected: selectedPlatforms.contains(pf),
                  onPressed: () {
                    var selected = selectedPlatforms.contains(pf);
                    if (selected) {
                      selectedPlatforms.remove(pf);
                    } else {
                      selectedPlatforms.add(pf);
                    }
                    setState(() {});
                  },
                ),
              ),
          ],
        ),

        ///endregion

        ///region 来源
        Row(
          children: [
            const Icon(
              MdiIcons.listBoxOutline,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.filterBySource.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
        Wrap(
          children: [
            for (var app in selectedAppInfos)
              Container(
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: RoundedChip(
                  showCheckmark: false,
                  deleteIcon: const Icon(
                    Icons.delete,
                    color: Colors.blueGrey,
                  ),
                  onDeleted: () {
                    final appId = app.appId;
                    setState(() {
                      selectedSourceIds.remove(appId);
                      selectedAppInfos.removeWhere(
                            (item) => item.appId == appId,
                      );
                    });
                  },
                  label: Text(app.name),
                  avatar: Image.memory(app.iconBytes),
                ),
              ),
            RoundedChip(
              avatar: const Icon(Icons.add),
              label: Text(TranslationKey.selection.tr),
              onPressed: () {
                final devState = ref.read(deviceProvider).requireValue;
                showAppSelection(
                  context,
                  AppSelectionRouteArgs(
                    loadDeviceName: devState.getName,
                    selectedIds: selectedSourceIds,
                    loadAppInfos: () async {
                      // 合并已同步来源（DB）与本机已安装应用，按 设备+包名 去重
                      // 等待来源数据加载完成后再读取，避免首次进入时来源列表为空
                      final sourceState = await ref.read(clipboardSourceProvider.future);
                      final list = sourceState.appInfos
                          .map((item) => LocalAppInfo.fromAppInfo(item, false))
                          .toList();
                      list.addAll(sourceState.installedApps);
                      return list
                          .distinct((item) => item.devId + item.appId)
                          .toList();
                    },
                    onSelectedDone: (selected) {
                      setState(() {
                        selectedAppInfos = List.from(selected);
                        selectedSourceIds.addAll(
                          selected.map((item) => item.appId),
                        );
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),

        ///endregion

        ///region 触发时机
        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailTriggerLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        TinySegmentedControl.fromStrings(
          options: RuleTrigger.values.map((e) => e.tr).toList(),
          selectedIndex: RuleTrigger.values.indexOf(selectedTrigger),
          selectedBackgroundColor: _segmentSelectedBackgroundColor,
          selectedColor: _segmentSelectedColor,
          backgroundColor: context.isDarkMode ? _segmentDarkBackgroundColor : _segmentLightBackgroundColor,
          onSelected: (i) {
            final trigger = RuleTrigger.values[i];
            setState(() {
              selectedTrigger = trigger;
            });
            if (trigger == RuleTrigger.onSms) {
              //切换短信触发时引导授权，保证短信监听可用
              rulesExecutor.requestSmsPermissionIfNeeded(
                promptText: TranslationKey.syncSettingsSmsPermissionRequired.tr,
              );
            }
          },
        ),

        ///endregion
      ].separateWith(const SizedBox(height: 5)),
    );
  }

  Widget buildRuleTabBar(BuildContext context) {
    final bool isUseScript = ruleContentType == RuleContentType.script;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///region 规则
        Row(
          children: [
            const Icon(
              Icons.rule,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailRuleLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        Row(
          children: [
            // 切换分段即同时切换规则类型与显示内容，二者合一
            TinySegmentedControl.fromStrings(
              options: [
                TranslationKey.ruleDetailRegexTab.tr,
                TranslationKey.ruleDetailScriptTab.tr,
              ],
              selectedIndex: tabIndex,
              backgroundColor: context.isDarkMode ? _segmentDarkBackgroundColor : _segmentLightBackgroundColor,
              selectedBackgroundColor: _segmentSelectedBackgroundColor,
              selectedColor: _segmentSelectedColor,
              onSelected: (i) {
                setState(() {
                  ruleContentType = i == 0 ? RuleContentType.regex : RuleContentType.script;
                });
              },
            ),
            const Spacer(),
            if (isUseScript)
              IconButton(
                onPressed: () {
                  setState(() {
                    autoWrapText = !autoWrapText;
                  });
                },
                tooltip: TranslationKey.ruleDetailAutoWrapTooltip.tr,
                icon: Icon(
                  Icons.wrap_text,
                  size: 20,
                  fontWeight: autoWrapText ? FontWeight.bold : null,
                  color: autoWrapText ? Colors.blueGrey : Colors.grey,
                ),
                visualDensity: VisualDensity.compact,
              ),
            if (isUseScript)
              IconButton(
                onPressed: () {
                  setState(() {
                    isScriptFullScreen = true;
                  });
                },
                tooltip: TranslationKey.ruleDetailFullScreenTooltip.tr,
                icon: const Icon(
                  Icons.fullscreen,
                  size: 20,
                  color: Colors.blueGrey,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),

        ///endregion
      ],
    );
  }

  Widget buildRuleContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IndexedStack(
          index: tabIndex,
          children: [buildRuleRegexTab, buildRuleScriptViewTab].asMap().entries.map((entry) {
            final index = entry.key;
            final builder = entry.value;
            return Visibility(
              maintainState: true,
              visible: tabIndex == index,
              child: builder(context),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildRuleRegexTab(BuildContext context) {
    final whiteBlackModeValues = <WhiteBlackMode>[
      WhiteBlackMode.defaultMode,
      WhiteBlackMode.black,
      WhiteBlackMode.white,
    ];
    final currentMode = whiteBlackMode;
    final isBlacklistMode = currentMode == WhiteBlackMode.black;
    final isWhitelistMode = currentMode == WhiteBlackMode.white;
    // 识别规则输入列：上方为识别规则输入框
    final ruleInputColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: 10.insetV,
          child: Text(TranslationKey.ruleDetailRegexLabel.tr),
        ),
        TextField(
          maxLines: regexTextFieldMaxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hint: Text(TranslationKey.ruleDetailRegexHint.tr),
          ),
          controller: regexTextController,
        ),
      ],
    );
    // 提取规则输入列：上方为提取开关与输入框，开关与标签左右分开布局
    final extractInputColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TranslationKey.ruleDetailExtractContent.tr),
            // 启用开关，带"启用"文案标签
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(TranslationKey.enable.tr),
                Checkbox(
                  value: isAllowExtractData,
                  onChanged: (checked) {
                    setState(() {
                      isAllowExtractData = checked ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextField(
          enabled: isAllowExtractData,
          maxLines: regexTextFieldMaxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hint: Text(TranslationKey.ruleDetailRegexHint.tr),
          ),
          controller: extractTextController,
        ),
      ],
    );
    // 小屏设备上下布局，桌面端左右并排布局
    final inputsLayout = context.isCompactScreen
        ? Column(
            children: [
              ruleInputColumn,
              const SizedBox(height: 10),
              extractInputColumn,
            ],
          )
        : Row(
            children: [
              Expanded(child: ruleInputColumn),
              const SizedBox(width: 5),
              Expanded(child: extractInputColumn),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 正则使用提示：前缀"提示："加粗突出，内容为说明文案
        Container(
          margin: 10.insetT,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${TranslationKey.tips.tr}: ',
                  style: TextStyle(
                    color: Colors.brown.withAlpha(200),
                  ),
                ),
                TextSpan(
                  text: TranslationKey.ruleDetailRegexTip.tr,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
        inputsLayout,

        ///region 规则模式
        Row(
          children: [
            const Icon(
              Icons.swipe,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailModeLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        TinySegmentedControl.fromStrings(
          options: whiteBlackModeValues.map((mode) => mode.tr).toList(),
          selectedIndex: whiteBlackModeValues.indexOf(currentMode),
          selectedBackgroundColor: _segmentSelectedBackgroundColor,
          selectedColor: _segmentSelectedColor,
          backgroundColor: context.isDarkMode ? _segmentDarkBackgroundColor : _segmentLightBackgroundColor,
          onSelected: (i) {
            setState(() {
              whiteBlackMode = whiteBlackModeValues[i];
            });
          },
        ),

        ///endregion
        ///region 动作
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.touch_app,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              TranslationKey.ruleDetailActionLabel.tr,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: isBlacklistMode ? false : isAllowPostAddTags,
              onChanged: isBlacklistMode
                  ? null
                  : (checked) {
                      setState(() {
                        isAllowPostAddTags = checked ?? false;
                      });
                    },
            ),
            Text(TranslationKey.ruleDetailAddTagLabel.tr),
            if (isAllowPostAddTags && !isBlacklistMode)
              RoundedChip(
                avatar: const Icon(Icons.add),
                label: Text(TranslationKey.add.tr),
                onPressed: () {
                  dialogManager.open(
                    context,
                    TextEditDialog(
                      title: TranslationKey.ruleDetailAddTagDialogTitle.tr,
                      labelText: TranslationKey.pleaseInput.tr,
                      initStr: '',
                      verify: (str) => str.isNotEmpty,
                      errorText: TranslationKey.cannotEmpty.tr,
                      onOk: (String str) {
                        setState(() {
                          postTags.add(str);
                        });
                      },
                    ),
                  );
                },
              ),
          ],
        ),
        if (isAllowPostAddTags && !isBlacklistMode)
          Wrap(
            children: [
              for (var tag in postTags)
                Container(
                  margin: const EdgeInsets.only(right: 5, bottom: 5),
                  child: RoundedChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        postTags.remove(tag);
                      });
                    },
                    deleteIcon: const Icon(
                      Icons.delete,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            Checkbox(
              value: isBlacklistMode ? false : isPreventSync,
              onChanged: isBlacklistMode
                  ? null
                  : (checked) {
                      setState(() {
                        isPreventSync = checked ?? false;
                      });
                    },
            ),
            Text(TranslationKey.syncDisabled.tr),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: (isFinalRule || isBlacklistMode) && !isWhitelistMode,
              onChanged: currentMode != WhiteBlackMode.defaultMode
                  ? null
                  : (checked) {
                      setState(() {
                        isFinalRule = checked ?? false;
                      });
                    },
            ),
            Text(TranslationKey.ruleDetailFinalRule.tr),
          ],
        ),

        ///endregion
      ],
    );
  }

  void onSaveShortcutTriggered() {
    if (!shouldSave) {
      snackbar.success(
        context,
        TranslationKey.saveSuccess.tr,
      );
      return;
    }
    final newRule = toRule();
    if (newRule != null) {
      saveData(newRule);
    } else {
      logger.warn(tag, 'newRule is null');
    }
  }

  Widget buildRuleScriptViewTab(BuildContext context) {
    const height = 200.0;
    return LuaCodeEditView(
      editorKey: codeEditorKey,
      controller: codeController,
      autoWrapText: autoWrapText,
      height: height,
      onSaveShortcutTriggered: onSaveShortcutTriggered,
    );
  }

  Widget buildTestPanelWidget(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ScriptTestPanel(
        paramsController: testParamsContentController,
        showCompileInfo: false,
        showOutputsInfo: ruleContentType == RuleContentType.script,
        initialIndex: 0,
        runningResult: testResult,
        showUnfoldButton: false,
      ),
    );
  }

  Future<void> saveData(RuleItem newRule) async {
    final validateResult = newRule.validate();
    if (validateResult != null) {
      snackbar.warn(
        context,
        validateResult,
      );
      return;
    }
    final compileInfo = compile();
    if (compileInfo != null) {
      snackbar.warn(
        context,
        compileInfo,
      );
      return;
    }
    final success = await rulesExecutor.saveRule(newRule);
    if (!mounted) {
      return;
    }
    if (!success) {
      snackbar.error(
        context,
        TranslationKey.saveFailed.tr,
      );
      return;
    }
    snackbar.success(
      context,
      TranslationKey.saveSuccess.tr,
    );
    setState(() {
      originRule = newRule;
    });
  }

  Future<RuleExecResult> runningTest(RuleItem? newRule) async {
    return await rulesExecutor.test(
      newRule ?? originRule!,
      //todo type
      RuleExecParams(
        type: HistoryContentType.text,
        content: testParamsContentController.text,
        source: null,
      ),
    );
  }

  ///编译，若返回值为null代表编译成功
  String? compile() {
    final rule = toRule() ?? originRule;
    if (rule == null) {
      return TranslationKey.ruleCompileCodeNotFound.tr;
    }
    final (_, hash, errorMsg) = rulesExecutor.loadLuaUserFunc(
      '${rule.name}-temp',
      rule.script.content,
    );
    rulesExecutor.removeLuaUserFun(hash);
    return errorMsg;
  }

  @override
  Widget build(BuildContext context) {
    late Widget body;
    if (originRule == null) {
      body = const EmptyContent();
    } else {
      final newRule = toRule();
      final saveStatus = newRule != null && (newRule.isNewData || originRule.toString() != newRule.toString());
      if (saveStatus != shouldSave) {
        shouldSave = saveStatus;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          rulesExecutor.updateActiveItemChanged(shouldSave);
        });
      }
      if (isScriptFullScreen) {
        body = ScriptEditTestView(
          autoWrapText: autoWrapText,
          editorKey: codeEditorKey,
          paramsController: testParamsContentController,
          controller: codeController,
          showSaveButton: shouldSave,
          name: ruleNameTextController.text,
          onSaveTriggered: onSaveShortcutTriggered,
          compile: compile,
          onExitFullScreen: () {
            setState(() {
              isScriptFullScreen = false;
            });
          },
          onRunButtonClicked: () {
            return runningTest(newRule);
          },
        );
      } else {
        body = Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                margin: contentMargin.insetAll,
                child: Column(
                  children: [
                    buildRuleInfo(context),
                    buildRuleTabBar(context),
                    buildRuleContent(context),
                    buildTestPanelWidget(context),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 30, bottom: 30),
                child: IntrinsicWidth(
                  child: Row(
                    children: <Widget>[
                      AnimatedScale(
                        duration: 200.ms,
                        scale: saveStatus ? 1 : 0,
                        child: FloatingActionButton(
                          heroTag: '$tag.save',
                          onPressed: () {
                            if (!saveStatus) {
                              return;
                            }
                            saveData(newRule);
                          },
                          tooltip: TranslationKey.save.tr,
                          child: const Icon(Icons.save_outlined),
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: '$tag.running-test',
                        onPressed: () async {
                          final result = await runningTest(newRule);
                          setState(() {
                            testResult = result;
                          });
                        },
                        tooltip: TranslationKey.ruleDetailRunTestTooltip.tr,
                        child: const Icon(Icons.play_arrow),
                      ),
                    ].separateWith(const SizedBox(width: 10)),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }
    if (context.isCompactScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationKey.ruleDetailPageTitle.tr),
        ),
        body: PopScope(
          canPop: !shouldSave,
          onPopInvokedWithResult: (bool didPop, dynamic result) {

            if (didPop) {
              rulesExecutor.updateSelectedRuleItem(null);
              return;
            }
            dialogManager.tips(
              context,
              text: TranslationKey.unsavedTips.tr,
              actions: DialogActions(
                cancel: const DialogAction(),
                confirm: DialogAction(
                  onPressed: () {
                    rulesExecutor.updateActiveItemChanged(false);
                    rulesExecutor.updateSelectedRuleItem(null);
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
