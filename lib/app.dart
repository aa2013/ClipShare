import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/routing/app_router.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/shared/widgets/layouts/custom_title_bar_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/gen/app_localizations.dart';

class ClipShareApp extends ConsumerWidget {
  const ClipShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(uiLocaleProvider);
    // 触发翻译对象绑定到 L10nBridge，供无 context 的代理调用点使用。
    ref.watch(appLocalizationsProvider);
    // TODO 主题待实现，后续补充 light/dark 主题及全局样式。
    var title = appName;
    return MaterialApp.router(
      title: title,
      locale: uiLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        return CustomTitleBarLayout(
          title: [
            const SizedBox(width: 5),
            logoImg,
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      }
    );
  }
}
