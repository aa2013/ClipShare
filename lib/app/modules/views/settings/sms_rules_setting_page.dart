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

class SmsRuleSettingPage extends StatelessWidget {
  SmsRuleSettingPage({super.key});

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return RuleSettingPage(
      title: TranslationKey.smsRuleSettingPageAppBarTitle.tr,
      initData: Rule.fromJson(
        (jsonDecode(
          appConfig.smsRules,
        )["data"] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      ),
      onAdd: (data) {
        var name = data.name;
        var rule = data.rule;
        if (name.isNullOrEmpty || rule.isNullOrEmpty) {
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
          appConfig.smsRules,
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
            "rule": RuleType.sms.name,
            "data": data,
          }),
        );
        await dbService.opRecordDao.removeRuleRecord(
          RuleType.sms.name,
          appConfig.userId,
        );
        await appConfig.setSmsRules(json);

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
