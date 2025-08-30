import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:re_editor/re_editor.dart';

class ContextMenuItemWidget extends PopupMenuItem<void> implements PreferredSizeWidget {
  ContextMenuItemWidget({
    super.key,
    required String text,
    required VoidCallback super.onTap,
  }) : super(
          child: Text(text),
        );

  @override
  Size get preferredSize => const Size(150, 25);
}

class ContextMenuControllerImpl implements SelectionToolbarController {
  const ContextMenuControllerImpl();

  @override
  void hide(BuildContext context) {}

  @override
  Future<void> show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) async {
    final selection = controller.selection;
    final menu = ContextMenu(
      entries: [
        if (selection.extentOffset != selection.baseOffset)
          MenuItem(
            label: TranslationKey.copyContent.tr,
            icon: Icons.copy,
            onSelected: () async {
              controller.copy();
            },
          ),
        MenuItem(
          label: TranslationKey.selectAll.tr,
          icon: Icons.select_all,
          onSelected: () async {
            controller.selectAll();
          },
        ),
      ],
      position: (anchors.secondaryAnchor ?? anchors.primaryAnchor) - const Offset(0, 70),
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
    Future.delayed(100.ms, () {
      controller.selection = selection;
    });
  }
}
