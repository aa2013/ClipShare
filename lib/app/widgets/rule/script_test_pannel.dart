import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/app/widgets/log_line_highlight.dart';
import 'package:clipshare/app/widgets/rule/rule_compile_info_highlight.dart';
import 'package:clipshare/app/widgets/rule/rule_result_highlight.dart';
import 'package:flutter/material.dart';

class ScriptTestPanel extends StatefulWidget {
  final bool showUnfoldButton;
  final TextEditingController paramsController;
  final RuleExecResult? runningResult;
  final String compileInfo;
  final bool showCompileInfo;
  final bool showOutputsInfo;
  final int initialIndex;
  final VoidCallback? onUnfoldButtonClicked;

  const ScriptTestPanel({
    super.key,
    required this.paramsController,
    this.runningResult,
    required this.showCompileInfo,
    this.showOutputsInfo = true,
    required this.initialIndex,
    this.compileInfo = "",
    this.showUnfoldButton = false,
    this.onUnfoldButtonClicked,
  });

  @override
  State<StatefulWidget> createState() => _ScriptTestPanelState();
}

class _ScriptTestPanelState extends State<ScriptTestPanel> {
  var panelIndex = 1;

  List<String> get tabs => [
    '参数',
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
    if (widget.runningResult != null) {
      child = RuleResultHighLight(result: widget.runningResult!);
    }
    return Container(
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
        const SizedBox(height: 2),
        Expanded(
          child: IndexedStack(
            index: panelIndex,
            children: [
              buildParamsPanel(context),
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
