library rules;

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/views/rules/rule_detail.dart';
import 'package:clipshare/app/modules/views/rules/rule_list_view.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesPage extends GetView<RulesController> {
  RulesPage({super.key});

  final appConfig = Get.find<ConfigService>();
  final ruleDao = Get.find<DbService>().ruleDao;

  Future<bool> _abortAskDialog(BuildContext context) async {
    var abort = false;
    if (controller.activeItemChanged.value) {
      DialogController? dialog;
      dialog = Global.showTipsDialog(
        context: context,
        autoDismiss: false,
        text: "尚有未保存的修改，确认继续操作？",
        showCancel: true,
        onCancel: () {
          abort = true;
          dialog?.close();
        },
        onOk: () {
          dialog?.close();
        },
      );
      await dialog?.future;
    }
    return abort;
  }

  Widget _buildRuleList(BuildContext context) {
    final listView = Obx(
      () => RuleListView(
        rules: controller.rules.value,
        disableDrag: controller.activeItemChanged.value,
        onDragged: () {
          // todo 同步
          controller.saveRules();
        },
        onItemChanged: (RuleItem item) {
          // todo 同步
          controller.saveRules();
          // ruleDao.updateRule(item.toRule());
        },
        onItemTap: (RuleItem item) async {
          final isCurrent = item.id == controller.selectedItem.value?.id;
          if (isCurrent) {
            return false;
          }
          if (await _abortAskDialog(context)) {
            return false;
          }
          controller.selectedItem.value = item;
          if (appConfig.isSmallScreen) {
            Get.to(_buildRuleDetail());
          }
          return true;
        },
        onItemAdd: (RuleItem newRule) async {
          if (await _abortAskDialog(context)) {
            return;
          }
          controller.rules.add(newRule);
          controller.selectedItem.value = newRule;
        },
        onItemRemove: (Set<int> ids) async {
          final loading = Global.showLoadingDialog(context: context, loadingText: TranslationKey.deleting.tr);
          final List<RuleItem> items = [];
          controller.rules.removeWhere((rule) {
            if (!ids.contains(rule.id)) {
              return false;
            }
            //未保存的直接删除
            if (rule.version <= 0) {
              return true;
            }
            //保存过的删除数据库数据
            items.add(rule);
            return true;
          });
          final List<RuleItem> replayItems = [];
          for (var rule in items) {
            final success = ((await ruleDao.remove(rule.id)) ?? 0) > 0;
            if (!success) {
              replayItems.add(rule);
            } else {
              //todo 同步数据
            }
          }
          if (replayItems.isNotEmpty) {
            controller.rules.addAll(replayItems);
            controller.rules.sort();
          }
          controller.saveRules();
          await loading.close();
          Global.showSnackBarSuc(text: TranslationKey.deleteSuccess.tr, context: context);
        },
      ),
    );
    if (appConfig.isSmallScreen) {
      return listView;
    }
    return SizedBox(
      width: 250,
      child: listView,
    );
  }

  Widget _buildRuleDetail() {
    return Padding(
      padding: 5.insetR,
      child: Obx(
        () => RuleDetail(
          rule: controller.selectedItem.value,
          onSaveClicked: (item) {
            for (var i = 0; i < controller.rules.length; i++) {
              var old = controller.rules[i];
              if (old.id != item.id) {
                continue;
              }

              item.version = DateTime.now().yyyyMMddHHmmss;
              late final Future<int> saveFuture;
              if (item.isNewData) {
                //todo 同步数据
                item.isNewData = false;
                saveFuture = ruleDao.addRule(item.toRule());
              } else {
                //todo 同步数据
                saveFuture = ruleDao.updateRule(item.toRule());
              }
              saveFuture.then((cnt) {
                if (cnt == 0) {
                  Global.showSnackBarErr(text: TranslationKey.saveFailed.tr, context: Get.context!);
                } else {
                  Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: Get.context!);
                  controller.rules[i] = item;
                  controller.loadLuaUserFunc(item.name, item.script.content, hash: item.id.toString());
                }
              });
              break;
            }
          },
          onSaveStatusChanged: (status) {
            controller.activeItemChanged.value = status;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appConfig.isSmallScreen) {
      return _buildRuleList(context);
    }
    return Container(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleList(context),
          Expanded(
            child: _buildRuleDetail(),
          ),
        ],
      ),
    );
  }
}
