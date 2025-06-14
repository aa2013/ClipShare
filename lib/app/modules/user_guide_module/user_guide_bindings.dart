import 'dart:io';

import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/handlers/guide/battery_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/environment_selections_guide.dart';
import 'package:clipshare/app/handlers/guide/finish_guide.dart';
import 'package:clipshare/app/handlers/guide/float_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/notify_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/storage_perm_guide.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UserGuideBinding implements Bindings {
  final appConfig = Get.find<ConfigService>();

  @override
  void dependencies() {
    bool showEnvGuide = false;
    if (Platform.isAndroid) {
      if (appConfig.osVersion >= 10) {
        showEnvGuide = true;
      } else {
        showEnvGuide = false;
        appConfig.setWorkingMode(EnvironmentType.androidPre10);
      }
    }
    Get.lazyPut(
      () => UserGuideController(
        [
          if (showEnvGuide) FloatPermGuide(),
          StoragePermGuide(),
          if (showEnvGuide) EnvironmentSelectionsGuide(),
          NotifyPermGuide(),
          BatteryPermGuide(),
          FinishGuide(),
        ],
      ),
    );
  }
}
