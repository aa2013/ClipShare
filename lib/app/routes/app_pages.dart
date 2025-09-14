import '../../app/modules/db_editor_module/db_editor_page.dart';
import '../../app/modules/db_editor_module/db_editor_bindings.dart';
import '../../app/modules/clean_data_module/clean_data_page.dart';
import '../../app/modules/clean_data_module/clean_data_bindings.dart';
import '../../app/modules/qr_code_scanner_module/qr_code_scanner_page.dart';
import '../../app/modules/qr_code_scanner_module/qr_code_scanner_bindings.dart';
import '../../app/modules/licenses_module/licenses_page.dart';
import '../../app/modules/licenses_module/licenses_bindings.dart';
import '../../app/modules/update_log_module/update_log_page.dart';
import '../../app/modules/update_log_module/update_log_bindings.dart';
import '../../app/modules/about_module/about_page.dart';
import '../../app/modules/about_module/about_bindings.dart';
import '../../app/modules/debug_module/debug_page.dart';
import '../../app/modules/debug_module/debug_bindings.dart';
import '../../app/modules/working_mode_selection_module/working_mode_selection_page.dart';
import '../../app/modules/working_mode_selection_module/working_mode_selection_bindings.dart';
import '../../app/modules/statistics_module/statistics_page.dart';
import '../../app/modules/statistics_module/statistics_bindings.dart';
import 'package:clipshare/app/modules/home_module/home_page.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_bindings.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_page.dart';
import 'package:clipshare/app/modules/views/welcome_page.dart';
import 'package:get/get.dart';

import '../../app/modules/authentication_module/authentication_bindings.dart';
import '../../app/modules/authentication_module/authentication_page.dart';
import '../../app/modules/device_module/device_bindings.dart';
import '../../app/modules/device_module/device_page.dart';
import '../../app/modules/history_module/history_bindings.dart';
import '../../app/modules/history_module/history_page.dart';
import '../../app/modules/home_module/home_bindings.dart';
import '../../app/modules/log_module/log_bindings.dart';
import '../../app/modules/log_module/log_page.dart';
import '../../app/modules/search_module/search_bindings.dart';
import '../../app/modules/search_module/search_page.dart';
import '../../app/modules/settings_module/settings_bindings.dart';
import '../../app/modules/settings_module/settings_page.dart';
import '../../app/modules/splash_module/splash_bindings.dart';
import '../../app/modules/splash_module/splash_page.dart';

part './app_routes.dart';
/**
 * GetX Generator - fb.com/htngu.99
 * */

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.WELCOME,
      page: () => WelcomePage(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.HISTORY,
      page: () => HistoryPage(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => SearchPage(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: Routes.DEVICE,
      page: () => DevicePage(),
      binding: DeviceBinding(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.AUTHENTICATION,
      page: () => AuthenticationPage(),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: Routes.LOG,
      page: () => LogPage(),
      binding: LogBinding(),
    ),
    GetPage(
      name: Routes.USER_GUIDE,
      page: () => UserGuidePage(),
      binding: UserGuideBinding(),
    ),
    GetPage(
      name: Routes.USER_GUIDE,
      page: () => UserGuidePage(),
      binding: UserGuideBinding(),
    ),
    GetPage(
      name: Routes.STATISTICS,
      page: () => StatisticsPage(),
      binding: StatisticsBinding(),
    ),
    GetPage(
      name: Routes.WORKING_MODE_SELECTION,
      page: () => WorkingModeSelectionPage(),
      binding: WorkingModeSelectionBinding(),
    ),
    GetPage(
      name: Routes.DEBUG,
      page: () => DebugPage(),
      binding: DebugBinding(),
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => AboutPage(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: Routes.UPDATE_LOG,
      page: () => UpdateLogPage(),
      binding: UpdateLogBinding(),
    ),
    GetPage(
      name: Routes.LICENSES,
      page: () => LicensesPage(),
      binding: LicensesBinding(),
    ),
    GetPage(
      name: Routes.QR_CODE_SCANNER,
      page: () => QRCodeScannerPage(),
      binding: QRCodeScannerBinding(),
    ),
    GetPage(
      name: Routes.CLEAN_DATA,
      page: () => CleanDataPage(),
      binding: CleanDataBinding(),
    ),
    GetPage(
      name: Routes.DB_EDITOR,
      page: () => DbEditorPage(),
      binding: DbEditorBinding(),
    ),
  ];
}
