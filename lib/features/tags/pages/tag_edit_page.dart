import 'package:clipshare/features/tags/providers/tag_edit_controller.dart';
import 'package:clipshare/features/tags/widgets/tag_edit_form.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 标签编辑页路由参数，go_router 通过 extra 携带目标历史记录 id。
class TagEditRouteArgs {
  final int hisId;

  const TagEditRouteArgs({required this.hisId});
}

/// 标签编辑页：小屏下由路由打开的独立页面。
///
/// 大屏不走此页，改由 [showTagEdit] 以弹窗形式呈现，复用同一个 [TagEditForm]。
class TagEditPage extends ConsumerWidget {
  final int hisId;

  const TagEditPage({
    super.key,
    required this.hisId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(tagEditControllerProvider(hisId)).value?.saving ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationKey.tagEditPageAppBarTitle.tr),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TagEditForm(hisId: hisId),
            ),
            _buildActionBar(context, ref, saving),
          ],
        ),
      ),
    );
  }

  /// 底部操作栏：取消关闭页面，保存成功后关闭。
  Widget _buildActionBar(BuildContext context, WidgetRef ref, bool saving) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: saving ? null : () => context.pop(),
            child: Text(TranslationKey.dialogCancelText.tr),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: saving ? null : () => _save(context, ref),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(TranslationKey.save.tr),
          ),
        ],
      ),
    );
  }

  /// 保存标签编辑结果，成功后返回上一页。
  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final saved = await ref.read(tagEditControllerProvider(hisId).notifier).save();
    if (saved && context.mounted) {
      context.pop();
    }
  }
}
