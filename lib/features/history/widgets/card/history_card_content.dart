import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/features/history/pages/preview_page.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

///历史记录中的卡片显示的内容
class HistoryCardContent extends StatelessWidget {
  final History history;
  final bool imgOnlyView;
  final bool imgSingleView;
  final bool showOriginData;
  final bool filePathSelectable;

  const HistoryCardContent({
    super.key,
    required this.history,
    this.imgOnlyView = false,
    this.imgSingleView = false,
    this.showOriginData = false,
    this.filePathSelectable = false,
  });

  Widget _renderText() {
    String content = '';
    if (history.extracted != null && !showOriginData) {
      content = history.extracted!;
    } else {
      if (history.isNotification) {
        content = history.notificationContent!;
      } else {
        content = history.content;
      }
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
    final content = history.content;
    Widget? image;
    if (history.isNotification) {
      if (history.notificationImage != null) {
        image = Image.memory(history.notificationImage!);
      }
      return const SizedBox.shrink();
    } else {
      image = Image.file(File(content));
    }
    return MouseRegion(
      cursor: isMobile ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: image,
        ),
        onTap: () {
          context.pushNamed(
            AppRoutes.imagePreview.name,
            extra: PreviewRouteArgs(
              history: history,
              onlyView: imgOnlyView,
              single: imgSingleView || history.isFile,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (history.isText || history.isSms) {
      return _renderText();
    }
    if (history.isImage || (history.isFile && history.content.isImageFileName)) {
      return _renderImage(context);
    }
    if (history.isFile) {
      Widget text;
      if(filePathSelectable){
        text = SelectableText(history.content);
      }else{
        text = Text(history.content);
      }
      return Row(
        children: [
          const Icon(
            Icons.file_present_outlined,
            color: Colors.blue,
          ),
          const SizedBox(width: 5),
          Expanded(child: text),
        ],
      );
    }
    if (history.isNotification) {
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
