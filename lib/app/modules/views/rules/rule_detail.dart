import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_params.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/models/rule/rule_regex_content.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/modules/views/rules/script_edit_test_view.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/lua_code_edit_view.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:clipshare/app/widgets/rule/script_test_pannel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:re_editor/re_editor.dart';

class RuleDetail extends StatefulWidget {
  final RuleItem? rule;
  final ValueChanged<RuleItem> onSaveClicked;
  final ValueChanged<bool>? onSaveStatusChanged;

  const RuleDetail({
    super.key,
    required this.rule,
    required this.onSaveClicked,
    this.onSaveStatusChanged,
  });

  @override
  State<StatefulWidget> createState() => _RuleDetailState();
}

class _RuleDetailState extends State<RuleDetail> with SingleTickerProviderStateMixin {
  final sourceService = Get.find<ClipboardSourceService>();
  final devService = Get.find<DeviceService>();
  final appConfig = Get.find<ConfigService>();
  final ruleController = Get.find<RulesController>();
  var shouldSave = false;
  static const tag = "RuleDetail";
  var isScriptFullScreen = false;

  static const int regexTextFieldMaxLines = 4;
  static const InputDecoration regexTextFieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
    hint: Text("请输入正则表达式"),
  );
  static const contentMargin = 5;
  late final TabController tabController;
  List<AppInfo> selectedAppInfos = [];
  var tabIndex = 0;
  final topContentKey = GlobalKey();

  RuleContentType get currentTab => tabIndex == 0 ? RuleContentType.regex : RuleContentType.script;

  Set<SupportPlatForm> selectedPlatforms = {SupportPlatForm.android};
  Set<String> selectedSourceIds = {};
  RuleTrigger selectedTrigger = RuleTrigger.onCopy;
  var ruleContentType = RuleContentType.regex;
  WhiteBlackMode? whiteBlackModes;
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
    return RuleItem(
      id: origin.id,
      version: origin.version,
      name: ruleNameTextController.text,
      platforms: selectedPlatforms,
      sources: selectedSourceIds,
      trigger: selectedTrigger,
      type: ruleContentType,
      regex: RuleRegexContent(
        mainRegex: regexTextController.text,
        allowExtractData: isAllowExtractData,
        extractRegex: extractTextController.text,
        allowAddTag: isAllowPostAddTags,
        tags: postTags,
        preventSync: isPreventSync,
        isFinal: isFinalRule,
        mode: whiteBlackModes,
      ),
      script: RuleScriptContent(
        language: RuleScriptLanguage.lua,
        content: codeController.text,
      ),
      enabled: origin.enabled,
      order: origin.order,
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
    updateTabIndex(ruleContentType);
    if (rule.script.content.trim().isNullOrEmpty) {
      codeController.text = Constants.luaTemplateRule;
    } else {
      codeController.text = rule.script.content;
    }
  }

  void updateTabIndex(RuleContentType type) {
    final newIndex = type == RuleContentType.regex ? 0 : 1;
    tabController.animateTo(newIndex);
  }

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    if (widget.rule != null) {
      updateStateData(widget.rule!);
    }
    tabController.addListener(onTabChanged);
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
    tabController.removeListener(onTabChanged);
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

  @override
  void didUpdateWidget(covariant RuleDetail oldWidget) {
    if (widget.rule != null) {
      updateStateData(widget.rule!);
    }
    super.didUpdateWidget(oldWidget);
  }

  void onTabChanged() {
    setState(() {
      tabIndex = tabController.index;
    });
  }

  Widget buildRuleInfo(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ///region 名称
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                "规则名称: ",
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          TextField(
            controller: ruleNameTextController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hint: Text("请输入规则名称"),
            ),
          ),

          ///endregion

          ///region 平台
          Row(
            children: [
              Icon(
                Icons.apps,
                color: Colors.blueGrey,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                "平台",
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
                    deleteIcon: Icon(
                      Icons.delete,
                      color: Colors.blueGrey,
                    ),
                    onDeleted: () {
                      final appId = app.appId;
                      setState(() {
                        selectedSourceIds.remove(appId);
                        selectedAppInfos.removeWhere((item) => item.appId == appId);
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
                  final page = AppSelectionPage(
                    loadDeviceName: devService.getName,
                    selectedIds: selectedSourceIds,
                    loadAppInfos: () {
                      final list = sourceService.appInfos.map((item) => LocalAppInfo.fromAppInfo(item, false)).toList();
                      return Future<List<LocalAppInfo>>.value(list);
                    },
                    onSelectedDone: (selected) {
                      setState(() {
                        selectedAppInfos = List.from(selected);
                        selectedSourceIds.addAll(selected.map((item) => item.appId));
                      });
                    },
                  );
                  if (appConfig.isSmallScreen) {
                    Get.to(page);
                  } else {
                    Global.showDialog(context, DynamicSizeWidget(child: page));
                  }
                },
              ),
            ],
          ),

          ///endregion

          ///region 触发时机
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blueGrey,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                "触发时机",
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),

          TinySegmentedControl.fromStrings(
            options: RuleTrigger.values.map((e) => e.tr).toList(),
            selectedIndex: RuleTrigger.values.indexOf(selectedTrigger),
            onSelected: (i) {
              setState(() {
                selectedTrigger = RuleTrigger.values[i];
              });
            },
          ),

          ///endregion
        ].separateWith(const SizedBox(height: 5)),
      ),
    );
  }

  Widget buildRuleTabBar(BuildContext context) {
    final bool isUseScript = currentTab == RuleContentType.script && ruleContentType == RuleContentType.script;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///region 规则
        Row(
          children: [
            Icon(
              Icons.rule,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              "规则",
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  TabBar(
                    tabAlignment: TabAlignment.start,
                    controller: tabController,
                    isScrollable: true,
                    dividerHeight: 0,
                    tabs: [
                      for (var tab in [RuleContentType.regex, RuleContentType.script])
                        Container(
                          margin: 5.insetV,
                          child: Row(
                            children: [
                              Checkbox(
                                value: ruleContentType == tab,
                                onChanged: (checked) {
                                  if (checked == true) {
                                    setState(() {
                                      ruleContentType = tab;
                                    });
                                    updateTabIndex(tab);
                                  }
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(tab == RuleContentType.regex ? '正则表达式' : "脚本"),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: 200.ms,
              scale: isUseScript ? 1 : 0,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    isScriptFullScreen = true;
                  });
                },
                tooltip: '进入全屏编辑模式',
                icon: const Icon(
                  Icons.fullscreen,
                  size: 20,
                  color: Colors.blueGrey,
                ),
                visualDensity: VisualDensity.compact,
              ),
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
    final whiteBlackModeLabels = ["默认", "黑名单", "白名单"];
    final whiteBlackModeValues = [null, WhiteBlackMode.black, WhiteBlackMode.white];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text("规则："),
                    margin: 10.insetV,
                  ),
                  TextField(
                    maxLines: regexTextFieldMaxLines,
                    decoration: regexTextFieldDecoration,
                    controller: regexTextController,
                  ),
                ],
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicWidth(
                    child: Row(
                      children: [
                        Checkbox(
                          value: isAllowExtractData,
                          onChanged: (checked) {
                            setState(() {
                              isAllowExtractData = checked ?? false;
                            });
                          },
                        ),
                        Text("提取内容"),
                      ],
                    ),
                  ),
                  SizedBox(height: 2),
                  TextField(
                    enabled: isAllowExtractData,
                    maxLines: regexTextFieldMaxLines,
                    decoration: regexTextFieldDecoration,
                    controller: extractTextController,
                  ),
                ],
              ),
            ),
          ],
        ),

        ///region 规则模式
        Row(
          children: [
            Icon(
              Icons.swipe,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              "规则模式",
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),

        TinySegmentedControl.fromStrings(
          options: whiteBlackModeLabels,
          selectedIndex: whiteBlackModeValues.indexOf(whiteBlackModes),
          onSelected: (i) {
            setState(() {
              whiteBlackModes = whiteBlackModeValues[i];
            });
          },
        ),

        ///endregion
        ///region 动作
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              "动作",
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: whiteBlackModeLabels == WhiteBlackMode.black ? false : isAllowPostAddTags,
              onChanged: whiteBlackModeLabels == WhiteBlackMode.black
                  ? null
                  : (checked) {
                      setState(() {
                        isAllowPostAddTags = checked ?? false;
                      });
                    },
            ),
            Text("添加标签："),
            if (isAllowPostAddTags && whiteBlackModeLabels != WhiteBlackMode.black)
              RoundedChip(
                avatar: const Icon(Icons.add),
                label: Text(TranslationKey.add.tr),
                onPressed: () {
                  Global.showDialog(
                    context,
                    TextEditDialog(
                      title: '添加标签',
                      labelText: TranslationKey.pleaseInput.tr,
                      initStr: '',
                      verify: (str) => str.isNotEmpty,
                      errorText: '不能为空',
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
        if (isAllowPostAddTags && whiteBlackModeLabels != WhiteBlackMode.black)
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
              value: whiteBlackModeLabels == WhiteBlackMode.black ? false : isPreventSync,
              onChanged: whiteBlackModeLabels == WhiteBlackMode.black
                  ? null
                  : (checked) {
                      setState(() {
                        isPreventSync = checked ?? false;
                      });
                    },
            ),
            Text("阻止同步"),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: isFinalRule,
              onChanged: (checked) {
                setState(() {
                  isFinalRule = checked ?? false;
                });
              },
            ),
            Text("终止后续规则"),
          ],
        ),

        ///endregion
      ],
    );
  }

  void onSaveShortcutTriggered() {
    if (!shouldSave) {
      Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
      return;
    }
    final newRule = toRule();
    if (newRule != null) {
      saveData(newRule);
    } else {
      Log.warn(tag, "newRule is null");
    }
  }

  Widget buildRuleScriptViewTab(BuildContext context) {
    const height = 200.0;
    return LuaCodeEditView(
      controller: codeController,
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
        showOutputsInfo: currentTab == RuleContentType.script,
        initialIndex: 0,
        runningResult: testResult,
        showUnfoldButton: false,
      ),
    );
  }

  void saveData(RuleItem newRule) {
    final validateResult = newRule.validate();
    if (validateResult != null) {
      Global.showSnackBarWarn(text: validateResult, context: context);
      return;
    }
    widget.onSaveClicked(newRule);
    setState(() {
      originRule = newRule;
    });
  }

  RuleExecResult runningTest(RuleItem? newRule) {
    return ruleController.test(
      newRule ?? originRule!,
      //todo type
      RuleExecParams(type: HistoryContentType.text, content: testParamsContentController.text, source: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    late Widget body;
    if (widget.rule == null || originRule == null) {
      body = EmptyContent();
    } else {
      final newRule = toRule();
      final saveStatus = newRule != null && (newRule.version == 0 || originRule.toString() != newRule.toString());
      if (saveStatus != shouldSave) {
        shouldSave = saveStatus;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSaveStatusChanged?.call(shouldSave);
        });
      }
      if (isScriptFullScreen) {
        body = ScriptEditTestView(
          paramsController: testParamsContentController,
          controller: codeController,
          showSaveButton: shouldSave,
          name: ruleNameTextController.text,
          onSaveTriggered: onSaveShortcutTriggered,
          compile: () {
            final rule = toRule() ?? originRule;
            if (rule == null) {
              return "Not found code";
            }
            final (_, hash, errorMsg) = ruleController.loadLuaUserFunc(
              "${rule.name}-temp",
              rule.script.content,
            );
            ruleController.removeLuaUserFun(hash);
            return errorMsg;
          },
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
                        onPressed: () {
                          final result = runningTest(newRule);
                          setState(() {
                            testResult = result;
                          });
                        },
                        tooltip: '运行测试',
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
    if (appConfig.isSmallScreen) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("规则详情"),
        ),
        body: body,
      );
    } else {
      return body;
    }
  }
}
