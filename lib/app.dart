import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/core/widgets/clipshare_title_bar_layout.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/routing/router.dart';
import 'package:clipshare/shared/widgets/base/app_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app/app_theme.dart';
import 'l10n/gen/app_localizations.dart';

class ClipShareApp extends ConsumerStatefulWidget {
  const ClipShareApp({super.key});

  @override
  ConsumerState<ClipShareApp> createState() => _ClipShareAppState();
}

class _ClipShareAppState extends ConsumerState<ClipShareApp> {
  late final Future<ThemeMode> _initialThemeModeFuture;

  @override
  void initState() {
    super.initState();
    // 启动主题只读取一次，避免设置页刷新 quickSettingsProvider 时重建根组件并打断主题动画。
    _initialThemeModeFuture = ref.read(appThemeProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(uiLocaleProvider);
    // 触发翻译对象绑定到 L10nBridge，供非 context 的代理调用点使用。
    ref.watch(appLocalizationsProvider);
    const title = appName;
    return FutureBuilder<ThemeMode>(
      future: _initialThemeModeFuture,
      builder: (context, snapshot) {
        final initialThemeMode = snapshot.data;
        if (initialThemeMode == null) {
          return const SizedBox.shrink();
        }
        return _buildApp(
          context: context,
          uiLocale: uiLocale,
          title: title,
          initialThemeMode: initialThemeMode,
        );
      },
    );
  }

  /// 构建应用根主题壳；启动主题来自持久化配置，运行中切换继续交给 ThemeSwitcher 动画处理。
  Widget _buildApp({
    required BuildContext context,
    required Locale uiLocale,
    required String title,
    required ThemeMode initialThemeMode,
  }) {
    return ThemeProvider(
      initTheme: _resolveInitialTheme(context, initialThemeMode),
      child: MaterialApp.router(
        title: title,
        locale: uiLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
        themeMode: initialThemeMode,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        builder: (BuildContext context, Widget? child) {
          return AppThemeSwitcher(
            child: Scaffold(
              body: ClipShareTitleBarLayout(
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
              ),
            ),
            onThemeChanged: () async {
              final appTheme = await ref.read(appThemeProvider.future);
              if (appTheme != ThemeMode.system) {
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.updateTheme(context.isPlatformDarkMode);
                // todo
                //Get.find<AndroidChannelService>().setHistoryFloatThemeMode(ThemeMode.system);
              });
            },
          );
        },
      ),
    );
  }

  /// 根据持久化主题模式解析启动主题，确保 ThemeProvider 首帧使用用户上次选择的主题。
  ThemeData _resolveInitialTheme(BuildContext context, ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      return darkThemeData;
    }
    if (mode == ThemeMode.light) {
      return lightThemeData;
    }
    final platformBrightness = context.platformBrightness;
    return platformBrightness == Brightness.dark
        ? darkThemeData
        : lightThemeData;
  }
}
