import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/extensions/history_data_extension.dart';
import 'package:clipshare/features/history/enums/history_card_menu_action.dart';
import 'package:clipshare/features/history/pages/preview_page.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/double_tap_wrapper.dart';
import 'package:clipshare/shared/widgets/base/theme_aware_context_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import 'history_card_content.dart';
import 'history_card_footer.dart';
import 'history_card_header.dart';
import 'history_native_drag_item_wrapper.dart';

class HistoryCard extends StatefulWidget {
  final History history;
  final bool selected;
  final bool selectMode;
  final bool imageMode;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelected;
  final ValueChanged<HistoryCardMenuAction> onMenuSelected;

  const HistoryCard({
    super.key,
    required this.history,
    required this.onMenuSelected,
    this.selected = false,
    this.selectMode = false,
    this.imageMode = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onToggleSelected,
  });

  @override
  State<StatefulWidget> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> with TickerProviderStateMixin {
  static const borderWidth = 2.0;
  static const borderRadius = 12.0;
  static final selectedBorder = BoxDecoration(
    border: Border.all(
      color: Colors.blue,
      width: borderWidth,
    ),
    borderRadius: BorderRadius.circular(borderRadius),
  );

  var slided = false;
  late final DoubleTapWrapper leftTapWrapper;
  late final DoubleTapWrapper rightTapWrapper;
  late final slidController = SlidableController(this);
  var showOriginData = false;

  @override
  void initState() {
    leftTapWrapper = DoubleTapWrapper(
      doubleTapInterval: 200.ms,
      onTap: (details) {
        if (slided) {
          slidController.close();
          return;
        }
        widget.onTap?.call();
      },
      onDoubleTap: isDesktop ? null : (details) => widget.onDoubleTap?.call(),
    );
    rightTapWrapper = DoubleTapWrapper(
      doubleTapInterval: 200.ms,
      onTap: (details) {
        showMenu(details!.globalPosition - const Offset(0, 70));
      },
      onDoubleTap: (details) {
        widget.history.copyContent(context: context, showFeedback: true);
      },
    );
    slidController.animation.addListener(() {
      slided = slidController.animation.value != 0;
    });
    super.initState();
  }

  @override
  void dispose() {
    slidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();
    final Widget child;
    if (widget.selectMode) {
      child = _buildSlidable(card);
    } else if (isDesktop) {
      child = HistoryNativeDragItemWrapper(history: widget.history, child: card);
    } else {
      child = card;
    }
    return GestureDetector(
      child: ClipRRect(child: child),
      onSecondaryTapDown: (details) {
        rightTapWrapper.call(details);
      },
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 0,
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: leftTapWrapper.wrapperTap,
        onLongPress: () {
          widget.onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          margin: widget.selected ? null : const EdgeInsets.all(borderWidth),
          decoration: widget.selected ? selectedBorder : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HistoryCardHeader(
                  history: widget.history,
                  showOriginData: showOriginData,
                  onOriginButtonClicked: () {
                    setState(() {
                      showOriginData = !showOriginData;
                    });
                  },
                ),
                buildContent(context),
                HistoryCardFooter(history: widget.history),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 多选模式下滑动卡片触发区间补选。
  Widget _buildSlidable(Widget child) {
    return Slidable(
      key: ValueKey(widget.history.id),
      controller: slidController,
      startActionPane: ActionPane(
        motion: const SizedBox.shrink(),
        extentRatio: 0.01,
        dismissible: DismissiblePane(
          onDismissed: () {},
          dismissThreshold: 0.1,
          confirmDismiss: () {
            slidController.close();
            widget.onToggleSelected?.call();
            return Future.value(false);
          },
        ),
        children: const [],
      ),
      child: child,
    );
  }

  Widget buildContent(BuildContext context) {
    if (widget.imageMode) {
      return IntrinsicHeight(
        child: GestureDetector(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(widget.history.content),
              fit: BoxFit.fitWidth,
              width: 200,
            ),
          ),
          onTap: () {
            context.pushNamed(
              AppRoutes.imagePreview.name,
              extra: PreviewRouteArgs(history: widget.history),
            );
          },
        ),
      );
    }
    return Expanded(
      child: Container(
        alignment: Alignment.centerLeft,
        child: HistoryCardContent(
          history: widget.history,
          showOriginData: showOriginData,
        ),
      ),
    );
  }

  ///右键菜单
  void showMenu(Offset? position) {
    final menu = ContextMenu(
      entries: [
        MyMenuItem(
          label: widget.history.top ? TranslationKey.cancelTopUp.tr : TranslationKey.topUp.tr,
          icon: widget.history.top ? Icons.push_pin : Icons.push_pin_outlined,
          onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.top),
        ),
        if (widget.history.isText)
          MyMenuItem(
            label: TranslationKey.segmentWords.tr,
            icon: Icons.grain,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.segment),
          ),
        if (widget.history.canCopy)
          MyMenuItem(
            label: TranslationKey.copyContent.tr,
            icon: Icons.copy,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.copy),
          ),
        if (!widget.history.isFile)
          MyMenuItem(
            label: widget.history.sync ? TranslationKey.resyncRecord.tr : TranslationKey.syncRecord.tr,
            icon: Icons.sync,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.resync),
          ),
        if (widget.history.isFile || widget.history.isImage)
          MyMenuItem(
            label: TranslationKey.openFile.tr,
            icon: Icons.file_open,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.openFile),
          ),
        if (widget.history.isFile || widget.history.isImage)
          MyMenuItem(
            label: TranslationKey.openFileFolder.tr,
            icon: Icons.folder,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.openFileFolder),
          ),
        MyMenuItem(
          label: TranslationKey.tagsManagement.tr,
          icon: Icons.tag,
          onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.tagManager),
        ),
        if (!widget.history.isFile && !widget.history.isImage)
          MyMenuItem(
            label: TranslationKey.modifyContent.tr,
            icon: Icons.edit_note,
            onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.modify),
          ),
        MyMenuItem(
          label: TranslationKey.delete.tr,
          icon: Icons.delete,
          onSelected: () => widget.onMenuSelected(HistoryCardMenuAction.delete),
        ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }
}
