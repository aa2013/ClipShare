import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class BatteryPermGuide extends BaseGuide {
  var permHandler = IgnoreBatteryHandler();

  BatteryPermGuide({super.allowSkip = true}) {
    super.widget = PermissionGuide(
      title: TranslationKey.batteryOptimization.tr,
      icon: Icons.filter_none_rounded,
      description: TranslationKey.batteryOptimizationPermGuideDesc.tr,
      grantPerm: permHandler.request,
      checkPerm: canNext,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
