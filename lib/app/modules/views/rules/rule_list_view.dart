import 'package:clipshare/app/data/enums/rule/rule_category.dart';
import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/models/rule/rule_regex_content.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/snowflake.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rule_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class RuleListView extends StatefulWidget {
  final List<RuleItem> rules;
  final VoidCallback onDragged;
  final ValueChanged<RuleItem> onItemChanged;
  final ValueChanged<RuleItem> onItemTap;
  final ValueChanged<RuleItem> onItemAdd;

  const RuleListView({
    super.key,
    required this.rules,
    required this.onDragged,
    required this.onItemChanged,
    required this.onItemTap,
    required this.onItemAdd,
  });

  @override
  State<StatefulWidget> createState() => _RuleListViewState();
}

class _RuleListViewState extends State<RuleListView> with SingleTickerProviderStateMixin {
  final TextEditingController textController = TextEditingController();
  late final TabController tabController;
  final Map<RuleCategory, ScrollController> scrollerControllersMap = {};
  final appConfig = Get.find<ConfigService>();
  static const tag = "RuleListView";
  var multiSelectMode = false;
  final Set<String> selectedRules = {};

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: Constants.ruleCategoryItems.length, vsync: this, initialIndex: 0);
  }

  Widget buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            autofocus: true,
            controller: textController,
            textAlignVertical: TextAlignVertical.center,
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
                onTap: () {},
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

  Widget buildRuleCard(RuleCategory category, RuleItem rule, [int? orderedIndex]) {
    return RuleCard(
      key: Key("$category-${rule.id}"),
      orderedIndex: orderedIndex,
      rule: rule,
      selected: selectedRules.contains(rule.id),
      selectMode: multiSelectMode,
      onEnabledChanged: (enabled) {
        setState(() {
          rule.enabled = enabled;
        });
        widget.onItemChanged(rule);
      },
      onTap: () {
        if (multiSelectMode) {
          return;
        }
        widget.onItemTap(rule);
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

  ScrollController getScrollController(RuleCategory category) {
    if (scrollerControllersMap.containsKey(category)) {
      return scrollerControllersMap[category]!;
    } else {
      var controller = ScrollController();
      scrollerControllersMap[category] = controller;
      return controller;
    }
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
            for (var tab in Constants.ruleCategoryItems)
              Container(
                margin: 5.insetV,
                child: Text(tab.tr),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: Constants.ruleCategoryItems.map((category) {
              final controller = getScrollController(category);
              final allRules = widget.rules;
              if (category == RuleCategory.all) {
                if (allRules.isEmpty) {
                  return Constants.emptyContent;
                }
                return ReorderableListView.builder(
                  scrollController: controller,
                  itemBuilder: (BuildContext context, int index) {
                    return buildRuleCard(category, allRules[index], index);
                  },
                  itemCount: allRules.length,
                  buildDefaultDragHandles: false,
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = allRules.removeAt(oldIndex);
                    allRules.insert(newIndex, item);
                    widget.onDragged();
                  },
                );
              }
              final rules = allRules.where((item) => item.category == category).toList();
              if (rules.isEmpty) {
                return Constants.emptyContent;
              }
              return ListView.builder(
                controller: controller,
                itemBuilder: (context, index) {
                  return buildRuleCard(category, rules[index], null);
                },
                itemCount: rules.length,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  FloatingActionButton _regularFab({
    required VoidCallback? onPressed,
    String? tooltip,
    Widget? child,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fabSize = appConfig.isSmallScreen ? ExpandableFabSize.regular : ExpandableFabSize.small;
    final fabButtonFun = appConfig.isSmallScreen ? _regularFab : FloatingActionButton.small;
    double distance = appConfig.isSmallScreen&&multiSelectMode?145:100;
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
          fabButtonFun(
            onPressed: () {
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
            child: Icon(selectedRules.length >= widget.rules.length ? Icons.deselect : Icons.select_all),
          ),
          if (!multiSelectMode)
            fabButtonFun(
              onPressed: () {},
              tooltip: TranslationKey.import.tr,
              child: Icon(MdiIcons.import),
            ),
          if (multiSelectMode)
            fabButtonFun(
              onPressed: () {},
              tooltip: TranslationKey.output.tr,
              child: Icon(MdiIcons.export),
            ),
          if (multiSelectMode)
            fabButtonFun(
              onPressed: () {},
              tooltip: TranslationKey.delete.tr,
              child: const Icon(Icons.delete),
            ),
          if (!multiSelectMode)
            fabButtonFun(
              onPressed: () {
                var currentTab = Constants.ruleCategoryItems[tabController.index];
                var newRule = RuleItem(
                  id: appConfig.snowflake.nextIdStr(),
                  version: 0,
                  name: "Rule${widget.rules.length + 1}",
                  category: currentTab == RuleCategory.all ? RuleCategory.common : currentTab,
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
                  ),
                  script: RuleScriptContent(language: RuleScriptLanguage.lua, content: ''),
                  allowSync: false,
                  enabled: false,
                );
                widget.onItemAdd(newRule);
                //controller 只会attach到当前的tab
                final controller = getScrollController(currentTab);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.hasClients) {
                    Log.debug(tag, "$currentTab scroller controller not clients");
                    return;
                  }
                  try {
                    controller.animateTo(
                      controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
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
              onPressed: () {
                setState(() {
                  multiSelectMode = false;
                  selectedRules.clear();
                });
              },
              tooltip: '退出选择模式',
              child: Icon(MdiIcons.cancel),
            ),
        ],
      ),
    );
  }
}
