import 'dart:async';

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
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

typedef OnRuleItemTap = FutureOr<bool> Function(RuleItem item);

class RuleListView extends StatefulWidget {
  final List<RuleItem> rules;
  final VoidCallback onDragged;
  final ValueChanged<RuleItem> onItemChanged;
  final OnRuleItemTap onItemTap;
  final ValueChanged<RuleItem> onItemAdd;
  final ValueChanged<Set<int>> onItemRemove;
  final bool disableDrag;

  const RuleListView({
    super.key,
    required this.rules,
    required this.onDragged,
    required this.onItemChanged,
    required this.onItemTap,
    required this.onItemAdd,
    required this.onItemRemove,
    this.disableDrag = false,
  });

  @override
  State<StatefulWidget> createState() => _RuleListViewState();
}

class _RuleListViewState extends State<RuleListView> with SingleTickerProviderStateMixin {
  final TextEditingController textController = TextEditingController();
  late final TabController tabController;
  final rulesController = ScrollController();
  final libsController = ScrollController();
  static const categories = [TranslationKey.rules, TranslationKey.libs];
  late final controllers = [rulesController, libsController];
  final appConfig = Get.find<ConfigService>();
  static const tag = "RuleListView";
  var multiSelectMode = false;
  final Set<int> selectedRules = {};
  RuleItem? activeItem;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this, initialIndex: 0);
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

  Widget buildRuleCard(RuleItem rule, [int? orderedIndex]) {
    return RuleCard(
      key: Key("${rule.id}"),
      orderedIndex: orderedIndex,
      rule: rule,
      isActive: rule.id == activeItem?.id,
      selected: selectedRules.contains(rule.id),
      selectMode: multiSelectMode,
      disabledDrag: widget.disableDrag,
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
        widget.onItemChanged(rule);
      },
      onTap: () async {
        if (multiSelectMode) {
          return;
        }
        final success = await widget.onItemTap(rule);
        if (success) {
          setState(() {
            activeItem = rule;
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
    if (widget.rules.isEmpty) {
      return Constants.emptyContent;
    }
    return Padding(
      padding: 2.insetH,
      child: ReorderableListView.builder(
        scrollController: rulesController,
        itemBuilder: (BuildContext context, int index) {
          return buildRuleCard(widget.rules[index], index);
        },
        itemCount: widget.rules.length,
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
          widget.onDragged();
        },
      ),
    );
  }

  Widget buildLibsListView() {
    return EmptyContent();
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
              child: const Icon(MdiIcons.import),
            ),
          if (multiSelectMode)
            fabButtonFun(
              onPressed: () {},
              tooltip: TranslationKey.output.tr,
              child: const Icon(MdiIcons.export),
            ),
          if (multiSelectMode)
            fabButtonFun(
              onPressed: () {
                widget.onItemRemove(selectedRules);
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
              onPressed: () {
                final currentTab = categories[tabController.index];
                final controller = controllers[tabController.index];
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
                  ),
                  script: RuleScriptContent(language: RuleScriptLanguage.lua, content: ''),
                  enabled: false,
                  order: widget.rules.length + 1,
                  isNewData: true,
                );
                widget.onItemAdd(newRule);
                //controller 只会attach到当前的tab
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
              child: const Icon(MdiIcons.cancel),
            ),
        ],
      ),
    );
  }
}
