import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class FloatPermGuide extends BaseGuide {
  var permHandler = FloatPermHandler();

  FloatPermGuide() {
    super.widget = PermissionGuide(
      title: TranslationKey.floatPermGuideTitle.tr,
      icon: Icons.filter_none_rounded,
      description: TranslationKey.floatPermGuideDesc.tr,
      grantPerm: permHandler.request,
      checkPerm: canNext,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
