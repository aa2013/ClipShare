import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'system_theme_mode_sync.dart';

class AppThemeSwitcher extends ConsumerWidget {
  final Widget child;
  final void Function() onThemeChanged;

  const AppThemeSwitcher({
    super.key,
    required this.child,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ThemeSwitchingArea(
      child: ThemeSwitcher(builder: (ctx) {
        return SystemThemeModeSync(
          onThemeChanged: onThemeChanged,
          child: child,
        );
      }),
    );
  }
}