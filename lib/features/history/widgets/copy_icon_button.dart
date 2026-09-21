import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';

class CopyIconButton extends StatefulWidget {
  final VoidCallback onClick;
  final String? tooltip;

  const CopyIconButton({
    super.key,
    required this.onClick,
    this.tooltip,
  });

  @override
  State<StatefulWidget> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<CopyIconButton> {
  bool copy = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(
        copy ? Icons.check : Icons.copy,
        color: Colors.blueGrey,
        size: 16,
      ),
      onPressed: () async {
        if (copy) {
          return;
        }
        widget.onClick();
        setState(() {
          copy = true;
        });
        await Future.delayed(300.ms);
        setState(() {
          copy = false;
        });
      },
      tooltip: widget.tooltip ?? TranslationKey.copyContent.tr,
    );
  }
}
