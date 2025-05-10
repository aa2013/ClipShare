import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/models/desktop_multi_window_args.dart';
import 'package:clipshare/app/modules/views/windows/file_sender/online_devices_window.dart';
import 'package:clipshare/app/modules/views/windows/history/history_window.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/services/window_service.dart';
import 'package:clipshare/app/translations/app_translations.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/base/custom_title_bar_layout.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'app/modules/splash_module/splash_page.dart';
import 'app/services/config_service.dart';
import 'app/services/db_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (PlatformExt.isDesktop) {
    // Must add this line.
    await windowManager.ensureInitialized();
  }
  await Get.putAsync(() => WindowControlService().initWindows());
  Widget home = SplashPage();
  String title = Constants.appName;
  var isMultiWindow = args.firstOrNull == 'multi_window';
  DesktopMultiWindowArgs? multiWindowArgs;
  if (isMultiWindow) {
    //子窗口
    final windowId = int.parse(args[1]);
    multiWindowArgs = DesktopMultiWindowArgs.fromJson(jsonDecode(args[2]));
    switch (multiWindowArgs.tag) {
      case MultiWindowTag.history:
        final wcs = Get.find<WindowControlService>();
        wcs.setAlwaysOnTop(true);
        wcs.setResizable(false);
        wcs.setMinimizable(false);
        wcs.setMaximizable(false);
        home = HistoryWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: multiWindowArgs.otherArgs,
        );
        title = multiWindowArgs.title;
        break;
      case MultiWindowTag.devices:
        final wcs = Get.find<WindowControlService>();
        wcs.setAlwaysOnTop(true);
        wcs.setResizable(false);
        wcs.setMinimizable(false);
        wcs.setMaximizable(false);
        home = FileSenderWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: multiWindowArgs.otherArgs,
        );
        title = multiWindowArgs.title;
        break;
    }
  }
  if (isMultiWindow) {
    await initMultiWindowServices();
    runMain(home, title, multiWindowArgs);
  } else {
    await initMainServices();
    runZonedGuarded(
          () {
        runMain(home, title, null);
      },
          (err, stack) {
        Log.error("globalError", "$err $stack");
      },
    );
  }
}

Future<void> initMainServices() async {
  await Get.putAsync(() => DbService().init());
  await Get.putAsync(() => ConfigService().init());
  Get.put<SocketService>(SocketService(), permanent: true);
  Get.put(AndroidChannelService().init());
  Get.put(ClipChannelService().init());
  Get.put(MultiWindowChannelService());
  Get.put(PendingFileService());
  await Get.putAsync(() => DeviceService().init(), permanent: true);
  await Get.putAsync(() => TagService().init(), permanent: true);
  await Get.putAsync(
        () => SyncingFileProgressService().init(),
    permanent: true,
  );
  if (PlatformExt.isDesktop) {
    await Get.putAsync(() => WindowService().init());
    await Get.putAsync(() => TrayService().init());
  }
}

Future<void> initMultiWindowServices() async {
  Get.put(MultiWindowChannelService());
  Get.put(PendingFileService());
}

final logoImg = Image.asset(
  'assets/images/logo/logo.png',
  width: 20,
  height: 20,
);

void runMain(Widget home, String title, DesktopMultiWindowArgs? args) {
  final isDarkMode = args?.themeMode == ThemeMode.dark || Get.isPlatformDarkMode;
  Locale? locale;
  final isMultiWindow = args != null;
  if (isMultiWindow) {
    windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    locale = Locale(args.languageCode, args.countryCode);
  }
  runApp(
    ThemeProvider(
      initTheme: isDarkMode ? darkThemeData : lightThemeData,
      builder: (context, theme) {
        return GetMaterialApp(
          translations: AppTranslation(),
          defaultTransition: Transition.native,
          builder: (ctx, child) {
            return ThemeSwitchingArea(
              child: Scaffold(
                appBar: null,
                // backgroundColor: Colors.transparent,
                body: CustomTitleBarLayout(
                  children: [
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
            );
          },
          title: title,
          initialRoute: isMultiWindow ? null : Routes.SPLASH,
          getPages: isMultiWindow ? null : AppPages.pages,
          theme: theme,
          home: isMultiWindow ? home : null,
          darkTheme: darkThemeData,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          fallbackLocale: const Locale('en', 'US'),
          supportedLocales: Constants.supportedLocales,
          localizationsDelegates: Constants.localizationsDelegates,
          scrollBehavior: MyCustomScrollBehavior(),
        );
      },
    ),
  );
}

//解决 Windows 端 SingleChildScrollView 无法水平滚动的问题
//https://stackoverflow.com/questions/72528980/horizontal-singlechildscrollview-not-working-inside-a-column-on-windows
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices =>
      {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
