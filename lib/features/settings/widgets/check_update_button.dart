import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///检查更新按钮：检查期间显示加载动画，无新版本时提示已是最新
class CheckUpdateButton extends ConsumerStatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  ConsumerState<CheckUpdateButton> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends ConsumerState<CheckUpdateButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: loading ? null : _checkUpdate,
      child: Visibility(
        replacement: Text(TranslationKey.checkUpdate.tr),
        visible: loading,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.0,
          ),
        ),
      ),
    );
  }

  /// 手动检查忽略跳过版本设置；更新弹窗统一交由根层事件监听展示。
  Future<void> _checkUpdate() async {
    setState(() {
      loading = true;
    });
    try {
      final updater = ref.read(appUpdateProvider.notifier);
      final result = await updater.checkUpdate(forceCheck: true);
      if (!mounted) {
        return;
      }
      if (result.status == .failed) {
        await dialogManager.tips(context, text: result.error.toString());
      } else if (result.status == .upToDate) {
        snackbar.success(context, TranslationKey.alreadyNewestAppVersion.tr);
      }
    } catch (err) {
      if (mounted) {
        await dialogManager.tips(
          context,
          text: err.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
}
