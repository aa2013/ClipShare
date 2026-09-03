import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/features/tags/pages/tag_edit_page.dart';
import 'package:clipshare/features/tags/providers/tag_edit_controller.dart';
import 'package:clipshare/features/tags/widgets/tag_edit_form.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 打开标签编辑入口。
///
/// 小屏下跳转到独立页面；大屏下以通用弹窗呈现，两者复用同一个 [TagEditForm]。
Future<void> showTagEdit(BuildContext context, WidgetRef ref, int hisId) async {
  if (context.isCompactScreen) {
    await context.pushNamed(
      AppRoutes.tagEdit.name,
      extra: TagEditRouteArgs(hisId: hisId),
    );
    return;
  }
  late final DialogController dialog;
  dialog = dialogManager.frame(
    context,
    icon: Icons.tag,
    title: TranslationKey.tagEditPageAppBarTitle.tr,
    // 表单自带滚动，避免弹窗再包一层滚动视图
    scrollable: false,
    dismissible: true,
    // 保存完成后再由回调主动关闭，而非点击即关
    autoDismiss: false,
    content: TagEditForm(hisId: hisId),
    actions: DialogActions(
      cancel: DialogAction(onPressed: () => dialog.close()),
      confirm: DialogAction(
        text: TranslationKey.save.tr,
        onPressed: () async {
          final saved = await ref.read(tagEditControllerProvider(hisId).notifier).save();
          if (saved) {
            await dialog.close();
          }
        },
      ),
    ),
  );
}
