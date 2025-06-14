import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class WorkingModeSelectionController extends GetxController {
  final Rx<EnvironmentType?> selected = Rx<EnvironmentType?>(null);
  final appConfig = Get.find<ConfigService>();
  final settingController = Get.find<SettingsController>();

  @override
  void onReady() {
    appConfig.selectingWorkingMode.value = true;
  }

  @override
  void onClose() {
    appConfig.selectingWorkingMode.value = false;
  }

  void onSelected(EnvironmentType? env) {
    selected.value = env;
  }

  Future<void> confirm() async {
    await appConfig.setWorkingMode(selected.value!);
    if (selected.value == EnvironmentType.none) {
      clipboardManager.stopListening();
    }
    settingController.checkAndroidEnvPermission(true);
    Get.back();
  }
}
