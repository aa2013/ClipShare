import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(HistoryController(), permanent: true);
    Get.put(SearchController(), permanent: true);
    Get.put(SyncFileController(), permanent: true);
    Get.put(RulesController(), permanent: true);
    assert((){
      Get.put(DebugController(), permanent: true);
      return true;
    }());
    Get.putAsync(() => ClipboardService().init(), permanent: true);
  }
}
