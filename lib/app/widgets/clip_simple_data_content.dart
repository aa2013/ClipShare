import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///历史记录中的卡片显示的内容
class ClipSimpleDataContent extends StatelessWidget {
  final ClipData clip;
  final bool imgOnlyView;
  final bool imgSingleView;

  const ClipSimpleDataContent({super.key, required this.clip, this.imgOnlyView = false, this.imgSingleView = false});

  Widget _renderText() {
    String content = "";
    if (clip.isNotification) {
      content = clip.notificationContent!;
    } else {
      content = clip.data.content;
    }
    content = content.substringMinLen(0, 200);
    return Text(
      content,
      textAlign: TextAlign.left,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _renderImage(BuildContext context) {
    final content = clip.data.content;
    Widget? image;
    if (clip.isNotification) {
      if (clip.notificationImage != null) {
        image = Image.memory(clip.notificationImage!);
      }
      return const SizedBox.shrink();
    } else {
      image = Image.file(File(content));
    }
    return MouseRegion(
      cursor: PlatformExt.isMobile ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: image,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewPage(
                clip: clip,
                onlyView: imgOnlyView,
                single: imgSingleView || clip.isFile,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (clip.isText || clip.isSms) {
      return _renderText();
    }
    if (clip.isImage || (clip.isFile && clip.data.content.isImageFileName)) {
      return _renderImage(context);
    }
    if (clip.isFile) {
      return Row(
        children: [
          const Icon(
            Icons.file_present_outlined,
            color: Colors.blue,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(child: Text(clip.data.content)),
        ],
      );
    }
    if (clip.isNotification) {
      return Row(
        children: [
          _renderImage(context),
          Expanded(child: _renderText()),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
