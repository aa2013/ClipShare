import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/features/history/pages/preview_page.dart';
import 'package:clipshare/features/history/widgets/card/history_card_content.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/widgets/base/theme_aware_context_menu_item.dart' hide MyMenuItem;
import 'package:clipshare/shared/widgets/largeText/large_text.dart';
import 'package:clipshare/shared/widgets/menu/my_menu.dart';
import 'package:clipshare/shared/widgets/menu/my_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_context_menu/src/widgets/menu_entry_widget.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class HistoryDrawerContentView extends StatefulWidget {
  final History history;
  final bool filePathSelectable;

  const HistoryDrawerContentView({
    super.key,
    required this.history,
    this.filePathSelectable = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _HistoryDrawerContentViewState();
  }
}

class _HistoryDrawerContentViewState extends State<HistoryDrawerContentView> {
  bool hasSelection = false;

  @override
  Widget build(BuildContext context) {
    final showText = widget.history.content;
    if (widget.history.isText || widget.history.isSms) {
      if (showText.length > 10000) {
        return LargeText(
          text: showText,
          readonly: true,
        );
      } else {
        return _buildSelectableLinkify(showText);
      }
    } else if (widget.history.isImage) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: _buildImage(constraints.maxWidth),
          );
        },
      );
    } else if (widget.history.isFile) {
      return HistoryCardContent(
        history: widget.history,
        filePathSelectable: widget.filePathSelectable,
      );
    } else if (widget.history.isNotification) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSelectableLinkify(widget.history.notificationContent!),
                _buildImage(constraints.maxWidth),
              ],
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSelectableLinkify(String text) {
    return SelectableLinkify(
      textAlign: TextAlign.left,
      text: text,
      options: const LinkifyOptions(humanize: false),
      linkStyle: const TextStyle(
        decoration: TextDecoration.none,
      ),
      onOpen: (link) async {
        if (!isDesktop) {
          link.url.askOpenUrl(context);
        } else {
          link.url.openUrl();
        }
      },
      onSelectionChanged:
          (TextSelection selection, SelectionChangedCause? cause) {
        hasSelection = selection.extentOffset != selection.baseOffset;
      },
      contextMenuBuilder: (context, editableTextState) {
        if (isDesktop) {
          final menus = [
            if (hasSelection)
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
          return MyMenu(
              menus: menus,
              position: editableTextState.contextMenuAnchors.primaryAnchor
          );
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
    );
  }

  Widget _buildImage(double maxWidth) {
    Widget image;
    if (widget.history.isImage) {
      image = Image.file(
        File(widget.history.content),
        fit: BoxFit.contain,
        width: maxWidth,
      );
    } else {
      if (widget.history.notificationImage == null) {
        return const SizedBox.shrink();
      }
      image = Image.memory(
        widget.history.notificationImage!,
        fit: BoxFit.contain,
        width: maxWidth,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        child: image,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewPage(
                history: widget.history,
              ),
            ),
          );
        },
      ),
    );
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
        ),
      ],
      borderRadius: state.borderRadius ?? BorderRadius.circular(4.0),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.8,
        end: 1.0,
      ),
      duration: 60.ms,
      builder: (context, value, child) {
        return Transform.scale(
          alignment: state.spawnAnchor,
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
                  children: [
                    for (final item in state.entries)
                      MenuEntryWidget(entry: item)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
