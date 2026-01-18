import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RulesController());
  }
}