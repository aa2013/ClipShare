import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CopyIconButton extends StatefulWidget {
  final ClipData clip;

  const CopyIconButton({
    super.key,
    required this.clip,
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
        var type = ClipboardContentType.parse(widget.clip.data.type);
        clipboardManager.copy(type, widget.clip.data.content);
        setState(() {
          copy = true;
        });
        await Future.delayed(300.ms);
        setState(() {
          copy = false;
        });
      },
      tooltip: TranslationKey.copyContent.tr,
    );
  }
}
