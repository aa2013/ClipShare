import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/features/licenses/constants/licenses.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:flutter/material.dart';

/// 第三方库许可证列表页，小屏使用 AppBar，大屏嵌入卡片布局。
class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final showAppBar = context.isCompactScreen;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        itemBuilder: (ctx, i) {
          if (i == 0 || i == licenseInfos.length + 1) {
            return const SizedBox(height: 5);
          }
          final item = licenseInfos[i - 1];
          return SettingCard(
            borderRadius: BorderRadius.circular(8),
            title: Text(item.name),
            description: Chip(
              label: Text(
                item.license,
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: const VisualDensity(
                horizontal: VisualDensity.minimumDensity,
                vertical: VisualDensity.minimumDensity,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.all(0),
            ),
            value: item.url,
            action: (url) {
              return IconButton(
                onPressed: () {
                  if (isDesktop) {
                    url.openUrl();
                  } else {
                    url.askOpenUrl(context);
                  }
                },
                icon: const Icon(Icons.link),
              );
            },
          );
        },
        separatorBuilder: (ctx, i) => const SizedBox(height: 5),
        itemCount: licenseInfos.length + 2,
      ),
    );
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationKey.about.tr),
        ),
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }
}
