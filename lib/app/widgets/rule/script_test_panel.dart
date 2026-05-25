import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/app/widgets/dot.dart';
import 'package:clipshare/app/widgets/log_line_highlight.dart';
import 'package:clipshare/app/widgets/rule/script_compile_info_highlight.dart';
import 'package:clipshare/app/widgets/rule/rule_result_highlight.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

class ScriptTestPanel extends StatefulWidget {
  final bool showUnfoldButton;
  final TextEditingController? paramsController;
  final RuleExecResult? runningResult;
  final WidgetBuilder? toolWidget;
  final String compileInfo;
  final bool showCompileInfo;
  final bool showOutputsInfo;
  final int initialIndex;
  final VoidCallback? onUnfoldButtonClicked;
  final WidgetBuilder? resultPanelBuilder;

  const ScriptTestPanel({
    super.key,
    required this.showCompileInfo,
    required this.initialIndex,
    this.runningResult,
    this.showOutputsInfo = true,
    this.paramsController,
    this.compileInfo = "",
    this.showUnfoldButton = false,
    this.onUnfoldButtonClicked,
    this.toolWidget,
    this.resultPanelBuilder,
  });

  @override
  State<StatefulWidget> createState() => _ScriptTestPanelState();
}

class _ScriptTestPanelState extends State<ScriptTestPanel> {
  var panelIndex = 1;

  Map<TranslationKey, bool> badgeShowFlags = {
    TranslationKey.scriptTestPanelParamsTab: false,
    TranslationKey.scriptTestPanelCompileInfoTab: false,
    TranslationKey.scriptTestPanelOutputTab: false,
    TranslationKey.scriptTestPanelRunResultTab: false,
  };

  List<TranslationKey> get tabs => [
    if (widget.paramsController != null) TranslationKey.scriptTestPanelParamsTab,
    if (widget.showCompileInfo) TranslationKey.scriptTestPanelCompileInfoTab,
    if (widget.showOutputsInfo) TranslationKey.scriptTestPanelOutputTab,
    TranslationKey.scriptTestPanelRunResultTab,
  ];

  @override
  void initState() {
    panelIndex = widget.initialIndex;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ScriptTestPanel oldWidget) {
    panelIndex = min(panelIndex, tabs.length - 1);
    if (oldWidget.compileInfo != widget.compileInfo) {
      const tab = TranslationKey.scriptTestPanelCompileInfoTab;
      if (tabs.length > panelIndex) {
        badgeShowFlags[tab] = tabs[panelIndex] != tab;
      }
    }
    if (oldWidget.runningResult != widget.runningResult) {
      const tab = TranslationKey.scriptTestPanelRunResultTab;
      if (tabs.length > panelIndex) {
        badgeShowFlags[tab] = tabs[panelIndex] != tab;
      }

      final oldOutputs = oldWidget.runningResult?.outputs;
      final newOutputs = widget.runningResult?.outputs;
      final outputsEquals = oldOutputs?.equalsAll(newOutputs ?? []) ?? false;
      if (!outputsEquals) {
        const tab = TranslationKey.scriptTestPanelOutputTab;
        if (tabs.length > panelIndex) {
          badgeShowFlags[tab] = tabs[panelIndex] != tab;
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget buildParamsPanel(BuildContext context) {
    return TextField(
      controller: widget.paramsController,
      maxLines: 4,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: TranslationKey.pleaseInput.tr,
      ),
    );
  }

  Widget buildCompileInfoPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFADAFB6)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 120,
        child: ScriptCompileHighLight(compileInfo: widget.compileInfo),
      ),
    );
  }

  Widget buildOutPutsInfoPanel(BuildContext context) {
    final outputs = widget.runningResult?.outputs ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFADAFB6)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: outputs.length,
        itemBuilder: (context, index) {
          return LogLineHighLight(log: outputs[index]);
        },
      ),
    );
  }

  Widget buildRunningResultPanel(BuildContext context) {
    Widget child = const SizedBox.shrink();
    if (widget.resultPanelBuilder != null) {
      child = widget.resultPanelBuilder!.call(context);
    } else {
      if (widget.runningResult != null) {
        child = RuleResultHighLight(result: widget.runningResult!);
      }
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFADAFB6)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TinySegmentedControl(
              options: tabs.map((tab) {
                const paramsTab = TranslationKey.scriptTestPanelParamsTab;
                final showBadge = tab != paramsTab && (badgeShowFlags[tab] ?? false);
                return Row(
                  children: [
                    Text(tab.tr),
                    if (showBadge)
                      Container(
                        margin: 4.insetL,
                        child: const Dot(radius: 3.0, color: Colors.green),
                      ),
                  ],
                );
              }).toList(),
              selectedBackgroundColor: Colors.blueGrey,
              selectedColor: Colors.white,
              backgroundColor: Get.isDarkMode ? const Color(0xff2e3b42) : const Color(0xffdde1e3),
              onSelected: (index) {
                setState(() {
                  panelIndex = index;
                  if (tabs.length > index) {
                    badgeShowFlags[tabs[index]] = false;
                  }
                });
              },
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ?widget.toolWidget?.call(context),
                  if (widget.showUnfoldButton)
                    IconButton(
                      onPressed: widget.onUnfoldButtonClicked,
                      tooltip: TranslationKey.scriptTestPanelCollapseTooltip.tr,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: IndexedStack(
            index: panelIndex,
            children: [
              if (widget.paramsController != null) buildParamsPanel(context),
              if (widget.showCompileInfo) buildCompileInfoPanel(context),
              if (widget.showOutputsInfo) buildOutPutsInfoPanel(context),
              buildRunningResultPanel(context),
            ],
          ),
        ),
      ],
    );
  }
}
