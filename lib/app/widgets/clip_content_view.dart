import 'dart:io';

import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/largeText/large_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class ClipContentView extends StatefulWidget {
  final ClipData clipData;

  const ClipContentView({super.key, required this.clipData});

  @override
  State<StatefulWidget> createState() {
    return _ClipContentViewState();
  }
}

class _ClipContentViewState extends State<ClipContentView> {
  static const tag = "ClipContentView";

  @override
  Widget build(BuildContext context) {
    final showText = widget.clipData.data.content;
    return widget.clipData.isText || widget.clipData.isSms
        ? showText.length > 10000
            ? LargeText(
                text: showText,
                readonly: true,
              )
            : SelectableLinkify(
                textAlign: TextAlign.left,
                text: showText,
                options: const LinkifyOptions(humanize: false),
                linkStyle: const TextStyle(
                  decoration: TextDecoration.none,
                ),
                onOpen: (link) async {
                  if (!PlatformExt.isDesktop) {
                    link.url.askOpenUrl();
                  } else {
                    link.url.openUrl();
                  }
                },
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: <ContextMenuButtonItem>[
                      ContextMenuButtonItem(
                        onPressed: () {
                          editableTextState.copySelection(
                            SelectionChangedCause.toolbar,
                          );
                        },
                        type: ContextMenuButtonType.copy,
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          editableTextState.selectAll(
                            SelectionChangedCause.toolbar,
                          );
                        },
                        type: ContextMenuButtonType.selectAll,
                      ),
                    ],
                  );
                },
              )
        : widget.clipData.isImage
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        child: Image.file(
                          File(widget.clipData.data.content),
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PreviewPage(
                                clip: widget.clipData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            : widget.clipData.isFile
                ? ClipSimpleDataContent(clip: widget.clipData)
                : const SizedBox.shrink();
  }
}
