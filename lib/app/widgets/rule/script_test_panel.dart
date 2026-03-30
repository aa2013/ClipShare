import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/app/widgets/log_line_highlight.dart';
import 'package:clipshare/app/widgets/rule/rule_compile_info_highlight.dart';
import 'package:clipshare/app/widgets/rule/rule_result_highlight.dart';
import 'package:flutter/material.dart';

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

  List<String> get tabs => [
    if (widget.paramsController != null) '参数',
    if (widget.showCompileInfo) '编译信息',
    if (widget.showOutputsInfo) '输出',
    '运行结果',
  ];

  @override
  void initState() {
    panelIndex = widget.initialIndex;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ScriptTestPanel oldWidget) {
    panelIndex = min(panelIndex, tabs.length - 1);
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
        child: RuleCompileHighLight(compileInfo: widget.compileInfo),
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
    }else{
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
            TinySegmentedControl.fromStrings(
              options: tabs,
              selectedBackgroundColor: Colors.blueGrey,
              selectedColor: Colors.white,
              onSelected: (index) {
                setState(() {
                  panelIndex = index;
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
                      tooltip: '折叠',
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
        const SizedBox(height: 2),
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
