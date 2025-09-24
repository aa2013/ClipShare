import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommonDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;

  const CommonDialog({
    super.key,
    required this.content,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: content,
      title: title,
      actions: actions,
    );
  }
}
