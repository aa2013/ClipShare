import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SystemThemeModeSync extends StatefulWidget {
  final Widget child;

  const SystemThemeModeSync({super.key, required this.child});

  @override
  State<SystemThemeModeSync> createState() => SystemThemeModeSyncState();
}

class SystemThemeModeSyncState extends State<SystemThemeModeSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final appConfig = Get.find<ConfigService>();
    if (appConfig.appTheme != ThemeMode.system) {
      return;
    }
    final isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appConfig.updateAppTheme(context, isDarkMode ? ThemeMode.dark : ThemeMode.light);
      Get.find<AndroidChannelService>().setHistoryFloatThemeMode(ThemeMode.system);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
