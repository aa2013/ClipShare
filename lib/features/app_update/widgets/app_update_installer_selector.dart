import 'package:clipshare/core/runtime/app_update/utils/app_update_installer.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/base/single_group_chip.dart';
import 'package:flutter/material.dart';

/// 桌面安装包类型选择，状态由更新窗口持有。
class AppUpdateInstallerSelector extends StatelessWidget {
  final List<String> types;
  final ValueNotifier<String?> selectedType;

  const AppUpdateInstallerSelector({super.key, required this.types, required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: selectedType,
      builder: (context, value, child) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(TranslationKey.selectInstallerType.tr,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: types.map((type) => SingleGroupChip(
              text: type,
              isSelected: type == value,
              onTap: () => selectedType.value = type,
            )).toList(),
          ),
          if (value == AppUpdateInstaller.zipExtension)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(TranslationKey.updateFromZipTips.tr, style: theme.textTheme.labelMedium),
            ),
        ],
      ),
    );
  }
}
