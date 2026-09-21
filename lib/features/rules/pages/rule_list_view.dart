import 'dart:async';

import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/rules/rules_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/rules/widgets/rule_card.dart';
import 'package:clipshare/features/rules/widgets/script_module_card.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/enums/support_platform.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/models/rule/rule_regex_content.dart';
import 'package:clipshare/shared/models/rule/rule_script_content.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnRuleItemTap = FutureOr<bool> Function(RuleItem item);
typedef OnScriptModuleItemTap = FutureOr<bool> Function(ScriptModule item);

class RuleListView extends ConsumerStatefulWidget {
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
  ConsumerState<RuleListView> createState() => _RuleListViewState();
}

class _RuleListViewState extends ConsumerState<RuleListView> with SingleTickerProviderStateMixin {
  final TextEditingController searchEditor = TextEditingController();
  late final TabController tabController;
  final rulesController = ScrollController();
  final scriptModulesController = ScrollController();
  static const categories = [TranslationKey.rules, TranslationKey.modules];
  late final controllers = [rulesController, scriptModulesController];
  static const tag = 'RuleListView';
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

  void _selectDefaultDesktopItem() {
    if (context.isCompactScreen) {
      return;
    }
    final rulesState = ref.read(rulesExecutorProvider).requireValue;
    if (rulesState.selectedRuleItem != null) {
      return;
    }
    if (rulesState.selectedLuaModuleItem != null) {
      return;
    }
    if (rulesState.rules.isEmpty) {
      return;
    }
    final rulesExecutor = ref.read(rulesExecutorProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rulesExecutor.updateSelectedRuleItem(rulesState.rules[0]);
    });
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
            decoration: context.noneBorderInputDecoration.copyWith(
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

  Widget buildRuleCard(BuildContext context, RuleItem rule, [int? orderedIndex]) {
    final isSmallScreen = context.isCompactScreen;
    return RuleCard(
      key: Key('${rule.id}'),
      orderedIndex: orderedIndex,
      rule: rule,
      isActive: !isSmallScreen && rule.id == activeRuleItem?.id && currentTab == TranslationKey.rules,
      selected: selectedRules.contains(rule.id),
      selectMode: multiSelectMode,
      showDragTooltip: isDesktop,
      disabledDrag: widget.disableRulesDrag || searchRules.length != widget.rules.length,
      onEnabledChanged: (enabled) {
        final validateResult = rule.validate();
        if (validateResult != null) {
          snackbar.warn(context, validateResult);
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
                              dialogManager.tips(context, text: TranslationKey.modulesTip.tr);
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
      return const EmptyContent();
    }
    return Padding(
      padding: 2.insetH,
      child: ReorderableListView.builder(
        scrollController: rulesController,
        itemBuilder: (BuildContext context, int index) {
          return buildRuleCard(context, searchRules[index], index);
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
      return const EmptyContent();
    }
    return Padding(
      padding: 2.insetH,
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final lib = searchScriptModules[index];
          final isSmallScreen = context.isCompactScreen;
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
              dialogManager.tips(
                context,
                title: TranslationKey.deleteTips.tr,
                text: TranslationKey.ruleListDeleteModuleConfirm.tr,
                actions: DialogActions(
                  cancel: const DialogAction(),
                  confirm: DialogAction(
                    onPressed: () {
                      widget.onScriptModuleItemRemove(lib);
                    },
                  ),
                ),
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
    _selectDefaultDesktopItem();
    final isSmallScreen = context.isCompactScreen;
    final fabSize = isSmallScreen ? ExpandableFabSize.regular : ExpandableFabSize.small;
    final fabButtonFun = isSmallScreen ? _regularFab : FloatingActionButton.small;
    double distance = isSmallScreen && multiSelectMode ? 145 : 100;
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
            onTrigger: _exitSelectionMode,
          ),
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.delete},
            onTrigger: _deleteSelectedRules,
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
                  heroTag: '$tag.multi-select',
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
                  heroTag: '$tag.remove',
                  onPressed: _deleteSelectedRules,
                  tooltip: '${TranslationKey.delete.tr} ($selectionDeleteShortcutLabel)',
                  child: const Icon(Icons.delete),
                ),
              if (!multiSelectMode)
                fabButtonFun(
                  heroTag: '$tag.add',
                  onPressed: () {
                    final controller = controllers[tabController.index];
                    if (isRulesTab) {
                      final idGenerator = ref.read(idProvider);
                      var newRule = RuleItem(
                        id: idGenerator.nextId(),
                        version: DateTime.now().yyyyMMddHHmmss,
                        name: 'Rule${widget.rules.length + 1}',
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
                      );
                      // 新建状态由 ScriptModule 扩展保存，避免污染数据库字段。
                      newScriptModule.isNewData = true;
                      widget.onScriptModuleItemAdd(newScriptModule);
                    }
                    //controller 只会attach到当前的tab
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!controller.hasClients) {
                        logger.debug(
                          tag,
                          '$currentTab scroller controller not clients',
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
                  heroTag: '$tag.exit-select-mode',
                  onPressed: _exitSelectionMode,
                  tooltip: '${TranslationKey.ruleListExitSelectionModeTooltip.tr} ($selectionExitShortcutLabel)',
                  child: const Icon(MdiIcons.cancel),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 退出规则多选模式；Esc 快捷键和 FAB 共用该入口，避免不同触发方式状态不一致。
  void _exitSelectionMode() {
    if (!isRulesTab || !multiSelectMode) {
      return;
    }
    _cancelSelect();
  }

  /// 删除当前选中的规则；Delete 快捷键和删除 FAB 共用该入口。
  void _deleteSelectedRules() {
    if (!isRulesTab || !multiSelectMode || selectedRules.isEmpty) {
      return;
    }
    final deletingRuleIds = selectedRules.toSet();
    dialogManager.tips(
      context,
      title: TranslationKey.deleteTips.tr,
      text: TranslationKey.multiDeleteAsk.trParams({'length': deletingRuleIds.length.toString()}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () => _confirmDeleteSelectedRules(deletingRuleIds),
        ),
      ),
    );
  }

  /// 确认后删除弹窗打开时选中的规则，避免弹窗期间选择变化影响删除目标。
  void _confirmDeleteSelectedRules(Set<int> ids) {
    if (ids.isEmpty) {
      return;
    }
    widget.onRuleItemRemove(ids);
    _cancelSelect();
  }

  void _cancelSelect() {
    setState(() {
      multiSelectMode = false;
      selectedRules.clear();
    });
  }
}
