import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/views/settings/rules_setting_page.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/dialog/rule_setting_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagRuleSettingPage extends StatelessWidget {
  TagRuleSettingPage({super.key});

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return RuleSettingPage(
      title: TranslationKey.tagRuleSettingPageAppBarTitle.tr,
      initData: Rule.fromJson(
        (jsonDecode(
          appConfig.tagRules,
        )["data"] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      ),
      onAdd: (data) {
        var tag = data.name;
        var rule = data.rule;
        if (tag.isNullOrEmpty || rule.isNullOrEmpty) {
          Global.showTipsDialog(
            context: context,
            text: TranslationKey.inputCompletedErrorText.tr,
          );
          return false;
        }
        return true;
      },
      editDialogLayout: (initData, onChange) {
        return RuleSettingDialog(
          labelText: TranslationKey.ruleSettingAddDialogLabel.tr,
          hintText: TranslationKey.ruleSettingAddDialogHint.tr,
          onChange: onChange,
          initData: initData,
        );
      },
      confirm: (res) async {
        var oldValue = jsonDecode(
          appConfig.tagRules,
        );
        var data = {
          "version": oldValue["version"] + 1,
          "data": res,
        };
        var json = jsonEncode(data);
        var opRecord = OperationRecord.fromSimple(
          Module.rules,
          OpMethod.update,
          jsonEncode({
            "rule": RuleType.tag.name,
            "data": data,
          }),
        );
        await dbService.opRecordDao.removeRuleRecord(
          RuleType.tag.name,
          appConfig.userId,
        );
        await appConfig.setTagRules(json);

        dbService.opRecordDao.addAndNotify(opRecord);
      },
      action: (i, rule, remove) {
        return IconButton(
          onPressed: () {
            remove(i, rule);
          },
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        );
      },
    );
  }
}
