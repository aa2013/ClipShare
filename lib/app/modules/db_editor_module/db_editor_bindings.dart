import 'package:clipshare/app/modules/db_editor_module/db_editor_controller.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DbEditorBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DbEditorController());
  }
}