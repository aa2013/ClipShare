import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class DragFileMask extends StatelessWidget {
  final void Function() onCloseBtnClicked;

  const DragFileMask({
    super.key,
    required this.onCloseBtnClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.file_upload_outlined,
          size: 50,
          color: Colors.blueGrey,
        ),
        const SizedBox(height: 32),
        Text(
          TranslationKey.dragFileToSend.tr,
          style: const TextStyle(color: Colors.blueGrey, fontSize: 22),
        ),
        const SizedBox(height: 32),
        Tooltip(
          message: TranslationKey.close.tr,
          child: IconButton(
            onPressed: onCloseBtnClicked,
            icon: const Icon(Icons.close, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}
