import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/licenses_module/licenses_controller.dart';
import 'package:clipshare/app/modules/licenses_module/licenses_page.dart';
import 'package:clipshare/app/modules/update_log_module/update_log_controller.dart';
import 'package:clipshare/app/modules/update_log_module/update_log_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AboutController extends GetxController {
  final appConfig = Get.find<ConfigService>();

  void gotoLicensesPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.LICENSES);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(LicensesController());
      homeController.pushDrawer(
        widget: LicensesPage(),
        beforeClosed: () {
          Get.delete<LicensesController>();
          return true;
        },
      );
    }
  }

  void gotoUpdateLogsPage() {
    if (appConfig.isSmallScreen) {
      Get.toNamed(Routes.UPDATE_LOG);
    } else {
      final homeController = Get.find<HomeController>();
      Get.put(UpdateLogController());
      homeController.pushDrawer(
        widget: UpdateLogPage(),
        beforeClosed: () {
          Get.delete<UpdateLogController>();
          return true;
        },
      );
    }
  }
}
