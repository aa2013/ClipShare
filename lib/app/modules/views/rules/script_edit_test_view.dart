import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/lua_code_edit_view.dart';
import 'package:clipshare/app/widgets/rule/script_test_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:re_editor/re_editor.dart';

class ScriptEditTestView extends StatefulWidget {
  final CodeLineEditingController controller;
  final Key? editorKey;
  final TextEditingController paramsController;
  final String name;
  final VoidCallback? onExitFullScreen;
  final VoidCallback onSaveTriggered;
  final RuleExecResult Function() onRunButtonClicked;
  final String? Function() compile;
  final bool showSaveButton;
  final bool autoWrapText;

  const ScriptEditTestView({
    super.key,
    this.editorKey,
    this.autoWrapText = false,
    required this.controller,
    required this.paramsController,
    required this.name,
    required this.onSaveTriggered,
    required this.onRunButtonClicked,
    required this.compile,
    required this.showSaveButton,
    this.onExitFullScreen,
  });

  @override
  State<StatefulWidget> createState() => _ScriptEditTestViewState();
}

class _ScriptEditTestViewState extends State<ScriptEditTestView> {
  final appConfig = Get.find<ConfigService>();
  final splitViewController = MultiSplitViewController(
    areas: [
      Area(flex: 1),
      Area(size: kPanelHeight),
    ],
  );
  static const double kPanelHeight = 150;
  RuleExecResult? runningResult;
  var compileInfo = '';

  @override
  void initState() {
    widget.controller.addListener(onCodeContentChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(onCodeContentChanged);
    super.dispose();
  }

  void onCodeContentChanged() {
    if (widget.controller.text.trim().isEmpty) {
      setState(() {
        compileInfo = TranslationKey.ruleCompileFailedPrefix.trParams({
          "message": TranslationKey.ruleCompileCodeEmpty.tr,
        });
      });
      return;
    }
    late String compileResult;
    try {
      final result = widget.compile();
      if (result == null) {
        compileResult = TranslationKey.ruleCompileSuccess.tr;
      } else {
        compileResult = TranslationKey.ruleCompileFailedPrefix.trParams({
          "message": result,
        });
      }
    } catch (err, stack) {
      compileResult = TranslationKey.ruleCompileFailedPrefix.trParams({
        "message": "$err\n$stack",
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          compileInfo = compileResult;
        });
      }
    });
  }

  Widget buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
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
              const SizedBox(width: 5),
              Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.showSaveButton
              ? () {
                  final compileInfo = widget.compile();
                  if (compileInfo != null) {
                    Global.showSnackBarWarn(
                      text: compileInfo,
                      context: context,
                    );
                    return;
                  }
                  widget.onSaveTriggered();
                }
              : null,
          tooltip: widget.showSaveButton ? TranslationKey.save.tr : TranslationKey.saved.tr,
          icon: Icon(
            Icons.save,
            size: 20,
            color: widget.showSaveButton ? Colors.blueGrey : Colors.grey,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () {
            var area = splitViewController.getArea(1);
            if ((area.size ?? 0) < 20) {
              area.size = kPanelHeight;
            } else {
              area.size = 0;
            }
          },
          tooltip: TranslationKey.scriptEditTestViewPanelTooltip.tr,
          icon: const Icon(
            Icons.dashboard,
            size: 20,
            color: Colors.blueGrey,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () {
            final result = widget.onRunButtonClicked();
            setState(() {
              runningResult = result;
            });
          },
          tooltip: TranslationKey.scriptEditTestViewRunTooltip.tr,
          icon: const Icon(
            Icons.play_arrow,
            size: 20,
            color: Colors.green,
          ),
          visualDensity: VisualDensity.compact,
        ),
        if (!appConfig.isSmallScreen)
          IconButton(
            onPressed: widget.onExitFullScreen,
            tooltip: TranslationKey.scriptEditTestViewExitFullScreenTooltip.tr,
            icon: const Icon(
              Icons.fullscreen_exit,
              size: 20,
              color: Colors.blueGrey,
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(context),
        Expanded(
          child: Stack(
            children: [
              LuaCodeEditView(
                autoWrapText: widget.autoWrapText,
                editorKey: widget.editorKey,
                controller: widget.controller,
                onSaveShortcutTriggered: widget.onSaveTriggered,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDivider(
    Axis axis,
    int index,
    bool resizable,
    bool dragging,
    bool highlighted,
    MultiSplitViewThemeData themeData,
  ) {
    final bar = Container(
      margin: 2.insetV,
      child: IntrinsicWidth(
        child: SizedBox(
          width: 50,
          height: 10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
    return bar;
  }

  @override
  Widget build(BuildContext context) {
    var view = MultiSplitView(
      controller: splitViewController,
      axis: Axis.vertical,
      pushDividers: false,
      builder: (BuildContext context, Area area) {
        if (area.index == 0) {
          return buildEditor(context);
        }
        return ScriptTestPanel(
          paramsController: widget.paramsController,
          showCompileInfo: true,
          compileInfo: compileInfo,
          runningResult: runningResult,
          initialIndex: 2,
          showUnfoldButton: true,
          onUnfoldButtonClicked: () {
            splitViewController.getArea(1).size = 0;
          },
        );
      },
    );
    return Padding(
      padding: 5.insetAll,
      child: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerPainter: DividerPainters.grooved1(
            color: Colors.indigo[300]!,
            highlightedColor: Colors.blueGrey,
            animationDuration: 200.ms,
          ),
        ),
        child: view,
      ),
    );
  }
}
