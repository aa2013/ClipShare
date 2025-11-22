import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_controller.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _FinishGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          TranslationKey.completed.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(
          height: 20,
        ),
        const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Text(TranslationKey.completedGuideTitleDescription.tr),
        ),
        TextButton.icon(
          onPressed: _gotoHomePage,
          icon: const Icon(Icons.arrow_circle_right, color: Colors.blue),
          label: Text(TranslationKey.enterSoftware.tr),
        ),
      ],
    );
  }

  void _gotoHomePage() {
    final controller = Get.find<UserGuideController>();
    controller.gotoHomePage();
  }
}

class FinishGuide extends BaseGuide {
  bool? hasPerm;

  FinishGuide() {
    super.widget = _FinishGuide();
    canNext().then((has) {
      hasPerm = has;
    });
  }

  @override
  Future<bool> canNext() async {
    return true;
  }
}
