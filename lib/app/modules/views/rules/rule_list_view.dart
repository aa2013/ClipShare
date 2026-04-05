import 'dart:async';

import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/models/rule/rule_regex_content.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rule/lua_lib_card.dart';
import 'package:clipshare/app/widgets/rule/rule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

typedef OnRuleItemTap = FutureOr<bool> Function(RuleItem item);
typedef OnLuaLibItemTap = FutureOr<bool> Function(RuleLib item);

class RuleListView extends StatefulWidget {
  final List<RuleItem> rules;
  final List<RuleLib> luaLibs;
  final VoidCallback onRuleDragged;
  final ValueChanged<RuleItem> onRuleItemChanged;
  final OnRuleItemTap onRuleItemTap;
  final ValueChanged<RuleItem> onRuleItemAdd;
  final ValueChanged<Set<int>> onRuleItemRemove;
  final OnLuaLibItemTap onLuaLibItemTap;
  final ValueChanged<RuleLib> onLuaLibItemAdd;
  final ValueChanged<RuleLib> onLuaLibItemRemove;
  final bool disableRulesDrag;
  final RuleItem? activeRuleItem;
  final RuleLib? activeLuaLibItem;

  const RuleListView({
    super.key,
    required this.rules,
    required this.luaLibs,
    required this.onRuleDragged,
    required this.onRuleItemChanged,
    required this.onRuleItemTap,
    required this.onRuleItemAdd,
    required this.onRuleItemRemove,
    required this.onLuaLibItemTap,
    required this.onLuaLibItemAdd,
    required this.onLuaLibItemRemove,
    this.disableRulesDrag = false,
    this.activeRuleItem,
    this.activeLuaLibItem,
  });

  @override
  State<StatefulWidget> createState() => _RuleListViewState();
}

class _RuleListViewState extends State<RuleListView>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchEditor = TextEditingController();
  late final TabController tabController;
  final rulesController = ScrollController();
  final libsController = ScrollController();
  static const categories = [TranslationKey.rules, TranslationKey.libs];
  late final controllers = [rulesController, libsController];
  final appConfig = Get.find<ConfigService>();
  static const tag = "RuleListView";
  var multiSelectMode = false;
  final Set<int> selectedRules = {};
  RuleItem? activeRuleItem;
  RuleLib? activeLuaLibItem;
  List<RuleItem> searchRules = [];
  List<RuleLib> searchLuaLibs = [];

  TranslationKey currentTab = TranslationKey.rules;

  bool get isRulesTab => currentTab == TranslationKey.rules;

  @override
  void initState() {
    super.initState();
    searchRules = List.from(widget.rules);
    searchLuaLibs = List.from(widget.luaLibs);
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

  void updateActiveItem(){
    activeRuleItem = widget.activeRuleItem;
    activeLuaLibItem = widget.activeLuaLibItem;
  }

  void updateSearchResult() {
    final search = searchEditor.text;
    searchRules = widget.rules
        .where((e) => search.isNullOrEmpty || e.name.containsIgnoreCase(search))
        .toList();
    searchLuaLibs = widget.luaLibs
        .where(
          (e) =>
              search.isNullOrEmpty ||
              e.libName.containsIgnoreCase(search) ||
              e.displayName.containsIgnoreCase(search),
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
            decoration: InputDecoration(
              isDense: true,
              contentPadding: 8.insetH,
              hintText: TranslationKey.search.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4), // 边框圆角
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 1.0,
                ), // 边框样式
              ),
              suffixIcon: InkWell(
                onTap: () {
                  setState(() {
                    updateSearchResult();
                  });
                },
                splashColor: Colors.black12,
                highlightColor: Colors.black12,
                borderRadius: BorderRadius.circular(50),
                child: Tooltip(
                  message: TranslationKey.search.tr,
                  child: const Icon(
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
    return RuleCard(
      key: Key("${rule.id}"),
      orderedIndex: orderedIndex,
      rule: rule,
      isActive: rule.id == activeRuleItem?.id && currentTab == TranslationKey.rules,
      selected: selectedRules.contains(rule.id),
      selectMode: multiSelectMode,
      disabledDrag:
          widget.disableRulesDrag || searchRules.length != widget.rules.length,
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
            activeLuaLibItem = null;
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
                child: Text(tab.tr),
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
          final item = widget.rules.removeAt(oldIndex);
          widget.rules.insert(newIndex, item);
          widget.onRuleDragged();
        },
      ),
    );
  }

  Widget buildLibsListView() {
    if (searchLuaLibs.isEmpty) {
      return Constants.emptyContent;
    }
    return Padding(
      padding: 2.insetH,
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final lib = searchLuaLibs[index];
          return LuaLibCard(
            luaLib: lib,
            isActive: lib.libName == activeLuaLibItem?.libName && currentTab == TranslationKey.libs,
            onTap: () async {
              final success = await widget.onLuaLibItemTap(lib);
              if (success) {
                setState(() {
                  activeLuaLibItem = lib;
                  activeRuleItem = null;
                });
              }
            },
            onDeleteTap: () {
              Global.showTipsDialog(
                context: context,
                title: TranslationKey.deleteTips.tr,
                text: TranslationKey.ruleListDeleteLibConfirm.tr,
                onOk: () {
                  widget.onLuaLibItemRemove(lib);
                },
                showCancel: true,
              );
            },
          );
        },
        itemCount: searchLuaLibs.length,
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
    final fabSize = appConfig.isSmallScreen
        ? ExpandableFabSize.regular
        : ExpandableFabSize.small;
    final fabButtonFun = appConfig.isSmallScreen
        ? _regularFab
        : FloatingActionButton.small;
    double distance = appConfig.isSmallScreen && multiSelectMode ? 145 : 100;
    return Scaffold(
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
              tooltip: selectedRules.length >= widget.rules.length
                  ? TranslationKey.cancelSelectAll.tr
                  : TranslationKey.selectAll.tr,
              child: Icon(
                selectedRules.length >= widget.rules.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: widget.rules.isEmpty ? Colors.grey : null,
              ),
            ),
          if (!multiSelectMode)
            fabButtonFun(
              heroTag: "$tag.import",
              onPressed: () {},
              tooltip: TranslationKey.import.tr,
              child: const Icon(MdiIcons.import),
            ),
          if (multiSelectMode)
            fabButtonFun(
              heroTag: "$tag.output",
              onPressed: () {},
              tooltip: TranslationKey.output.tr,
              child: const Icon(MdiIcons.export),
            ),
          if (multiSelectMode)
            fabButtonFun(
              heroTag: "$tag.remove",
              onPressed: () {
                widget.onRuleItemRemove(selectedRules);
                setState(() {
                  multiSelectMode = false;
                  selectedRules.clear();
                });
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
                  //lualib
                  var newLuaLib = RuleLib(
                    libName: 'LuaLib${widget.luaLibs.length + 1}',
                    displayName: 'LuaLib${widget.luaLibs.length + 1}',
                    language: RuleScriptLanguage.lua,
                    source: '',
                    version: 0,
                    isNewData: true,
                  );
                  widget.onLuaLibItemAdd(newLuaLib);
                }
                //controller 只会attach到当前的tab
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.hasClients) {
                    Log.debug(
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
                    Log.error(tag, err, stack);
                  }
                });
              },
              tooltip: TranslationKey.add.tr,
              child: const Icon(Icons.add),
            ),
          if (multiSelectMode)
            fabButtonFun(
              heroTag: "$tag.exit-select-mode",
              onPressed: () {
                setState(() {
                  multiSelectMode = false;
                  selectedRules.clear();
                });
              },
              tooltip: TranslationKey.ruleListExitSelectionModeTooltip.tr,
              child: const Icon(MdiIcons.cancel),
            ),
        ],
      ),
    );
  }
}
