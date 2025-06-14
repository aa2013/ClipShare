import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/widgets/environment_selections.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnvironmentSelectionsGuide extends BaseGuide {
  EnvironmentType? _selectedEnv;
  final appConfig = Get.find<ConfigService>();

  EnvironmentSelectionsGuide({super.allowSkip = false}) {
    super.widget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          TranslationKey.selectWorkMode.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        EnvironmentSelections(onSelected: onSelected),
      ],
    );
  }

  void onSelected(EnvironmentType? selected) {
    _selectedEnv = selected;
    final guideController = Get.find<UserGuideController>();
    guideController.canNextGuide.value = true;
    appConfig.setWorkingMode(_selectedEnv ?? EnvironmentType.none);
  }

  @override
  Future<bool> canNext() async {
    return _selectedEnv != null;
  }
}
