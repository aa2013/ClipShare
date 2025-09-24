import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class TextEditDialog extends StatefulWidget {
  final String title;
  final String? okText;
  final String labelText;
  final String initStr;
  final String hint;
  final bool autofocus;
  final bool Function(String)? verify;
  final String? errorText;
  final void Function(String) onOk;

  const TextEditDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.initStr,
    this.hint = "",
    required this.onOk,
    this.okText,
    this.verify,
    this.errorText,
    this.autofocus = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextEditDialogState();
  }
}

class _TextEditDialogState extends State<TextEditDialog> {
  final _editor = TextEditingController();
  bool showErr = false;

  @override
  Widget build(BuildContext context) {
    _editor.text = widget.initStr;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        height: 80,
        child: TextField(
          controller: _editor,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: widget.hint,
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            errorText: showErr ? widget.errorText : null,
          ),
          onChanged: (str) {
            if (showErr) {
              setState(() {
                showErr = false;
              });
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(TranslationKey.dialogCancelText.tr),
        ),
        TextButton(
          onPressed: () {
            if (widget.verify != null) {
              var valid = widget.verify!(_editor.text);
              if (!valid) {
                setState(() {
                  showErr = true;
                });
                return;
              }
            }
            Navigator.of(context).pop();
            widget.onOk.call(_editor.text);
          },
          child: Text(widget.okText ?? TranslationKey.dialogConfirmText.tr),
        ),
      ],
    );
  }
}
