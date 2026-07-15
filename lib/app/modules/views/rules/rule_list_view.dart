import 'dart:async';

import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/keyboard_shortcut.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/models/rule/rule_regex_content.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/app/widgets/rule/script_module_card.dart';
import 'package:clipshare/app/widgets/rule/rule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

typedef OnRuleItemTap = FutureOr<bool> Function(RuleItem item);
typedef OnScriptModuleItemTap = FutureOr<bool> Function(ScriptModule item);

class RuleListView extends StatefulWidget {
  final List<RuleItem> rules;
  final List<ScriptModule> scriptModules;
  final VoidCallback onRuleDragged;
  final ValueChanged<RuleItem> onRuleItemChanged;
  final OnRuleItemTap onRuleItemTap;
  final ValueChanged<RuleItem> onRuleItemAdd;
  final ValueChanged<Set<int>> onRuleItemRemove;
  final OnScriptModuleItemTap onScriptModuleItemTap;
  final ValueChanged<ScriptModule> onScriptModuleItemAdd;
  final ValueChanged<ScriptModule> onScriptModuleItemRemove;
  final bool disableRulesDrag;
  final RuleItem? activeRuleItem;
  final ScriptModule? activeLuaModuleItem;

  const RuleListView({
    super.key,
    required this.rules,
    required this.scriptModules,
    required this.onRuleDragged,
    required this.onRuleItemChanged,
    required this.onRuleItemTap,
    required this.onRuleItemAdd,
    required this.onRuleItemRemove,
    required this.onScriptModuleItemTap,
    required this.onScriptModuleItemAdd,
    required this.onScriptModuleItemRemove,
    this.disableRulesDrag = false,
    this.activeRuleItem,
    this.activeLuaModuleItem,
  });

  @override
  State<StatefulWidget> createState() => _RuleListViewState();
}

class _RuleListViewState extends State<RuleListView> with SingleTickerProviderStateMixin {
  final TextEditingController searchEditor = TextEditingController();
  late final TabController tabController;
  final rulesController = ScrollController();
  final scriptModulesController = ScrollController();
  static const categories = [TranslationKey.rules, TranslationKey.modules];
  late final controllers = [rulesController, scriptModulesController];
  final appConfig = Get.find<ConfigService>();
  static const tag = "RuleListView";
  var multiSelectMode = false;
  final Set<int> selectedRules = {};
  RuleItem? activeRuleItem;
  ScriptModule? activeScriptModuleItem;
  List<RuleItem> searchRules = [];
  List<ScriptModule> searchScriptModules = [];

  TranslationKey currentTab = TranslationKey.rules;

  bool get isRulesTab => currentTab == TranslationKey.rules;

  @override
  void initState() {
    super.initState();
    searchRules = List.from(widget.rules);
    searchScriptModules = List.from(widget.scriptModules);
    tabController = TabController(
      length: categories.length,
      vsync: this,
      initialIndex: 0,
    );
    tabController.addListener(() {
      setState(() {
        currentTab = categories[tabController.index];
      });
    });
    updateActiveItem();
  }

  @override
  void didUpdateWidget(covariant RuleListView oldWidget) {
    updateSearchResult();
    updateActiveItem();
    super.didUpdateWidget(oldWidget);
  }

  void updateActiveItem() {
    activeRuleItem = widget.activeRuleItem;
    activeScriptModuleItem = widget.activeLuaModuleItem;
  }

  void updateSearchResult() {
    final search = searchEditor.text;
    searchRules = widget.rules.where((e) => search.isNullOrEmpty || e.name.containsIgnoreCase(search)).toList();
    searchScriptModules = widget.scriptModules
        .where(
          (e) => search.isNullOrEmpty || e.moduleName.containsIgnoreCase(search) || e.displayName.containsIgnoreCase(search),
        )
        .toList();
  }

  Widget buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            autofocus: true,
            controller: searchEditor,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (text) {
              setState(() {
                updateSearchResult();
              });
            },
            decoration: noneBorderInputDecoration.copyWith(
              isDense: true,
              contentPadding: 8.insetH,
              hintText: TranslationKey.search.tr,
              suffixIcon: Tooltip(
                message: TranslationKey.search.tr,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      updateSearchResult();
                    });
                  },
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 25,
                  ),
                ),
              ),
            ),
            onSubmitted: (value) {},
          ),
        ),
      ],
    );
  }

  Widget buildRuleCard(RuleItem rule, [int? orderedIndex]) {
    final isSmallScreen = appConfig.isSmallScreen;
    return RuleCard(
      key: Key("${rule.id}"),
      orderedIndex: orderedIndex,
      rule: rule,
      isActive: !isSmallScreen && rule.id == activeRuleItem?.id && currentTab == TranslationKey.rules,
      selected: selectedRules.contains(rule.id),
      selectMode: multiSelectMode,
      showDragTooltip: PlatformExt.isDesktop,
      disabledDrag: widget.disableRulesDrag || searchRules.length != widget.rules.length,
      onEnabledChanged: (enabled) {
        final validateResult = rule.validate();
        if (validateResult != null) {
          Global.showSnackBarWarn(text: validateResult, context: context);
          return;
        }
        setState(() {
          rule.enabled = enabled;
          rule.version = DateTime.now().yyyyMMddHHmmss;
          rule.dirty = true;
        });
        widget.onRuleItemChanged(rule);
      },
      onTap: () async {
        if (multiSelectMode) {
          return;
        }
        final success = await widget.onRuleItemTap(rule);
        if (success) {
          setState(() {
            activeRuleItem = rule;
            activeScriptModuleItem = null;
          });
        }
      },
      onLongPress: !multiSelectMode
          ? () {
              setState(() {
                multiSelectMode = true;
                selectedRules.clear();
                selectedRules.add(rule.id);
              });
            }
          : null,
      onSelectedChanged: (checked) {
        setState(() {
          if (checked) {
            selectedRules.add(rule.id);
          } else {
            selectedRules.remove(rule.id);
          }
        });
      },
    );
  }

  Widget buildListView() {
    return Column(
      children: [
        TabBar(
          tabAlignment: TabAlignment.start,
          controller: tabController,
          isScrollable: true,
          dividerHeight: 0,
          tabs: [
            for (var tab in categories)
              Container(
                margin: 5.insetV,
                child: Row(
                  children: [
                    Text(tab.tr),
                    Visibility(
                      visible: tab == TranslationKey.modules,
                      child: Container(
                        margin: 3.insetL,
                        child: Tooltip(
                          message: TranslationKey.tips.tr,
                          child: GestureDetector(
                            onTap: () {
                              Global.showTipsDialog(context: context, text: TranslationKey.modulesTip.tr);
                            },
                            child: const Icon(
                              Icons.info_outline,
                              size: 15,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              buildRulesListView(),
              buildLibsListView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRulesListView() {
    if (searchRules.isEmpty) {
      return Constants.emptyContent;
    }
    return Padding(
      padding: 2.insetH,
      child: ReorderableListView.builder(
        scrollController: rulesController,
        itemBuilder: (BuildContext context, int index) {
          return buildRuleCard(searchRules[index], index);
        },
        itemCount: searchRules.length,
        buildDefaultDragHandles: false,
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final oldIndexRule = widget.rules[oldIndex];
          final newIndexRule = widget.rules[newIndex];
          oldIndexRule.version = DateTime.now().yyyyMMddHHmmss;
          newIndexRule.version = DateTime.now().yyyyMMddHHmmss;
          oldIndexRule.dirty = true;
          newIndexRule.dirty = true;
          setState(() {
            final item = widget.rules.removeAt(oldIndex);
            widget.rules.insert(newIndex, item);
            updateSearchResult();
          });
          widget.onRuleDragged();
        },
      ),
    );
  }

  Widget buildLibsListView() {
    if (searchScriptModules.isEmpty) {
      return Constants.emptyContent;
    }
    return Padding(
      padding: 2.insetH,
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final lib = searchScriptModules[index];
          final isSmallScreen = appConfig.isSmallScreen;
          return ScriptModuleCard(
            scriptModule: lib,
            isActive: !isSmallScreen && lib.moduleName == activeScriptModuleItem?.moduleName && currentTab == TranslationKey.modules,
            onTap: () async {
              final success = await widget.onScriptModuleItemTap(lib);
              if (success) {
                setState(() {
                  activeScriptModuleItem = lib;
                  activeRuleItem = null;
                });
              }
            },
            onDeleteTap: () {
              Global.showTipsDialog(
                context: context,
                title: TranslationKey.deleteTips.tr,
                text: TranslationKey.ruleListDeleteModuleConfirm.tr,
                onOk: () {
                  widget.onScriptModuleItemRemove(lib);
                },
                showCancel: true,
              );
            },
          );
        },
        itemCount: searchScriptModules.length,
      ),
    );
  }

  FloatingActionButton _regularFab({
    required VoidCallback? onPressed,
    String? tooltip,
    Widget? child,
    Object? heroTag,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      tooltip: tooltip,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fabSize = appConfig.isSmallScreen ? ExpandableFabSize.regular : ExpandableFabSize.small;
    final fabButtonFun = appConfig.isSmallScreen ? _regularFab : FloatingActionButton.small;
    double distance = appConfig.isSmallScreen && multiSelectMode ? 145 : 100;
    return PopScope(
      canPop: !multiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !multiSelectMode) {
          return;
        }
        setState(() {
          multiSelectMode = false;
          selectedRules.clear();
        });
      },
      child: CustomKeyboardListener(
        shortcuts: [
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.escape},
            onTrigger: _handleEscapeShortcut,
          ),
        ],
        child: Scaffold(
          body: Padding(
            padding: 5.insetAll,
            child: Column(
              children: [
                buildSearchField(),
                const SizedBox(height: 5),
                Expanded(child: buildListView()),
              ],
            ),
          ),
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: ExpandableFab(
            distance: distance,
            type: ExpandableFabType.fan,
            overlayStyle: const ExpandableFabOverlayStyle(blur: 8),
            openButtonBuilder: RotateFloatingActionButtonBuilder(
              fabSize: fabSize,
              child: Tooltip(
                message: TranslationKey.moreFilter.tr,
                child: const Icon(Icons.menu),
              ),
            ),
            closeButtonBuilder: DefaultFloatingActionButtonBuilder(
              fabSize: fabSize,
              child: Tooltip(
                message: TranslationKey.close.tr,
                child: const Icon(Icons.close),
              ),
            ),
            children: [
              if (isRulesTab)
                fabButtonFun(
                  heroTag: "$tag.multi-select",
                  onPressed: widget.rules.isEmpty
                      ? null
                      : () {
                          if (selectedRules.length >= widget.rules.length) {
                            setState(() {
                              selectedRules.clear();
                              multiSelectMode = false;
                            });
                            return;
                          }
                          selectedRules.addAll(widget.rules.map((item) => item.id));
                          if (selectedRules.isNotEmpty) {
                            setState(() {
                              multiSelectMode = true;
                            });
                          }
                        },
                  tooltip: selectedRules.length >= widget.rules.length ? TranslationKey.cancelSelectAll.tr : TranslationKey.selectAll.tr,
                  child: Icon(
                    selectedRules.length >= widget.rules.length ? Icons.deselect : Icons.select_all,
                    color: widget.rules.isEmpty ? Colors.grey : null,
                  ),
                ),
              // if (!multiSelectMode)
              //   fabButtonFun(
              //     heroTag: "$tag.import",
              //     onPressed: () {},
              //     tooltip: TranslationKey.import.tr,
              //     child: const Icon(MdiIcons.import),
              //   ),
              // if (multiSelectMode)
              //   fabButtonFun(
              //     heroTag: "$tag.output",
              //     onPressed: () {},
              //     tooltip: TranslationKey.output.tr,
              //     child: const Icon(MdiIcons.export),
              //   ),
              if (multiSelectMode)
                fabButtonFun(
                  heroTag: "$tag.remove",
                  onPressed: () {
                    widget.onRuleItemRemove(selectedRules);
                    _cancelSelect();
                  },
                  tooltip: TranslationKey.delete.tr,
                  child: const Icon(Icons.delete),
                ),
              if (!multiSelectMode)
                fabButtonFun(
                  heroTag: "$tag.add",
                  onPressed: () {
                    final controller = controllers[tabController.index];
                    if (isRulesTab) {
                      var newRule = RuleItem(
                        id: appConfig.snowflake.nextId(),
                        version: DateTime.now().yyyyMMddHHmmss,
                        name: "Rule${widget.rules.length + 1}",
                        platforms: SupportPlatForm.values.toSet(),
                        sources: {},
                        trigger: RuleTrigger.onCopy,
                        type: RuleContentType.regex,
                        regex: RuleRegexContent(
                          mainRegex: '',
                          allowExtractData: false,
                          extractRegex: '',
                          allowAddTag: false,
                          tags: {},
                          preventSync: false,
                          isFinal: false,
                          mode: WhiteBlackMode.defaultMode,
                        ),
                        script: RuleScriptContent(
                          language: RuleScriptLanguage.lua,
                          content: '',
                        ),
                        enabled: false,
                        order: widget.rules.length + 1,
                        isNewData: true,
                      );
                      widget.onRuleItemAdd(newRule);
                    } else {
                      //ScriptModule
                      var newScriptModule = ScriptModule(
                        moduleName: 'Module${widget.scriptModules.length + 1}',
                        displayName: 'Module${widget.scriptModules.length + 1}',
                        language: RuleScriptLanguage.lua,
                        source: '',
                        version: 0,
                        isNewData: true,
                      );
                      widget.onScriptModuleItemAdd(newScriptModule);
                    }
                    //controller 只会attach到当前的tab
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!controller.hasClients) {
                        logger.debug(
                          tag,
                          "$currentTab scroller controller not clients",
                        );
                        return;
                      }
                      try {
                        controller.animateTo(
                          controller.position.maxScrollExtent,
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        );
                      } catch (err, stack) {
                        logger.error(tag, err, stack);
                      }
                    });
                  },
                  tooltip: TranslationKey.add.tr,
                  child: const Icon(Icons.add),
                ),
              if (multiSelectMode)
                fabButtonFun(
                  heroTag: "$tag.exit-select-mode",
                  onPressed: _cancelSelect,
                  tooltip: TranslationKey.ruleListExitSelectionModeTooltip.tr,
                  child: const Icon(MdiIcons.cancel),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 仅在规则页多选状态下响应 Esc，避免模块列表或普通浏览状态被误关闭。
  void _handleEscapeShortcut() {
    if (!isRulesTab || !multiSelectMode) {
      return;
    }
    _cancelSelect();
  }

  void _cancelSelect(){
    setState(() {
      multiSelectMode = false;
      selectedRules.clear();
    });
  }

}
