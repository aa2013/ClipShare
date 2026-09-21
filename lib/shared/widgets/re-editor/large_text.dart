import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'find.dart';
import 'menu.dart';

class LargeText extends StatefulWidget {
  final String text;
  final bool readonly;
  final bool showLineNumber;
  final bool showSeparator;
  final bool findMode;
  final ValueChanged<bool>? onFindModeChanged;
  final CodeHighlightTheme? codeTheme;

  const LargeText({
    super.key,
    required this.text,
    required this.readonly,
    this.showLineNumber = false,
    this.showSeparator = false,
    this.findMode = false,
    this.codeTheme,
    this.onFindModeChanged,
  });

  @override
  State<StatefulWidget> createState() => _LargeTextState();
}

class _LargeTextState extends State<LargeText> {
  final CodeLineEditingController _controller = CodeLineEditingController();
  late final CodeFindController _findController;

  @override
  void initState() {
    _controller.text = widget.text;
    _findController = CodeFindController(_controller);
    if(widget.findMode){
      _findController.findMode();
    }
    _findController.addListener(() {
      widget.onFindModeChanged?.call(_findController.value != null);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LargeText oldWidget) {
    if(oldWidget.findMode != widget.findMode){
      if(widget.findMode) {
        _findController.findMode();
      }else{
        _findController.value = null;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      readOnly: widget.readonly,
      controller: _controller,
      findController: _findController,
      wordWrap: true,
      style: CodeEditorStyle(
        codeTheme: widget.codeTheme,
      ),
      indicatorBuilder: (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            Visibility(
              visible: widget.showLineNumber,
              child: DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              ),
            ),
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          ],
        );
      },
      findBuilder: (context, controller, readOnly) => CodeFindPanelView(controller: controller, readOnly: readOnly),
      toolbarController: const ContextMenuControllerImpl(),
      sperator: Visibility(
        visible: widget.showSeparator,
        child: Container(width: 1, color: const Color(0xADADAFB6)),
      ),
    );
  }
}
