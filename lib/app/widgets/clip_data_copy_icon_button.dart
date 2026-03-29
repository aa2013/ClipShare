import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';

class ClipDataCopyIconButton extends StatelessWidget {
  final ClipData clip;
  final String? tooltip;

  const ClipDataCopyIconButton({
    super.key,
    required this.clip,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return CopyIconButton(
      tooltip: tooltip,
      onClick: () async {
        final type = ClipboardContentType.parse(clip.data.type);
        final content = clip.data.extracted ?? clip.data.content;
        final result = await clipboardManager.copy(type, content);
        if (result) {
          Global.showSnackBarSuc(text: TranslationKey.copySuccess.tr, context: context);
        } else {
          Global.showSnackBarErr(text: TranslationKey.copySuccess.tr, context: context);
        }
      },
    );
  }
}

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
