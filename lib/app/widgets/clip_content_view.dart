import 'dart:io';

import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/largeText/large_text.dart';
import 'package:clipshare/app/widgets/menu/my_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_context_menu/src/widgets/menu_entry_widget.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../data/enums/translation_key.dart';
import 'menu/my_menu_item.dart';

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
  String selection = "";

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
                  if (PlatformExt.isDesktop) {
                    final menus = [
                      MyMenuItem(
                        label: TranslationKey.copyContent.tr,
                        icon: Icons.copy,
                        onSelected: () async {
                          editableTextState.copySelection(
                            SelectionChangedCause.toolbar,
                          );
                        },
                      ),
                      MyMenuItem(
                        label: TranslationKey.selectAll.tr,
                        icon: Icons.select_all,
                        onSelected: () async {
                          editableTextState.selectAll(
                            SelectionChangedCause.toolbar,
                          );
                        },
                      ),
                    ];
                    return MyMenu(menus: menus, position: editableTextState.contextMenuAnchors.primaryAnchor);
                  }
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

  /// Builds the context menu view.
  Widget _buildMenuView(BuildContext context, ContextMenuState state) {
    // final parentItem = state.parentItem;
    // if (parentItem?.isSubmenuItem == true) {
    //   print(parentItem?.debugLabel);
    // }

    var boxDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withOpacity(0.5),
          offset: const Offset(0.0, 2.0),
          blurRadius: 10,
          spreadRadius: -1,
        )
      ],
      borderRadius: state.borderRadius ?? BorderRadius.circular(4.0),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.8,
        end: 1.0,
      ),
      duration: const Duration(milliseconds: 60),
      builder: (context, value, child) {
        return Transform.scale(
          alignment: state.spawnAlignment,
          scale: value,
          child: Container(
            padding: state.padding,
            constraints: BoxConstraints(
              maxWidth: state.maxWidth,
            ),
            clipBehavior: state.clipBehavior,
            decoration: state.boxDecoration ?? boxDecoration,
            child: Material(
              type: MaterialType.transparency,
              child: IntrinsicWidth(
                child: Column(
                  children: [for (final item in state.entries) MenuEntryWidget(entry: item)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
