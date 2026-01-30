import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/working_mode_selection_module/working_mode_selection_controller.dart';
import 'package:clipshare/app/widgets/environment_selections.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class WorkingModeSelectionPage extends GetView<WorkingModeSelectionController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationKey.selectWorkMode.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.blueGrey,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnvironmentSelections(
                onSelected: controller.onSelected,
                selected: controller.selected.value,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: Get.back,
                      child: Text(
                        TranslationKey.dialogCancelText.tr,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Obx(
                      () => TextButton(
                        onPressed: controller.selected.value != null ? controller.confirm : null,
                        child: Text(
                          TranslationKey.dialogConfirmText.tr,
                          style: controller.selected.value != null ? const TextStyle(color: Colors.blue) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
