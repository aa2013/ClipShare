import 'package:clipshare/app/data/enums/rule/rule_category.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/views/rules/rule_detail.dart';
import 'package:clipshare/app/modules/views/rules/rule_list_view.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
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

  Widget _buildRuleList() {
    final listView = Obx(
      () => RuleListView(
        rules: controller.rules.value,
        onDragged: () {
          controller.saveRules();
          // todo 同步
        },
        onItemChanged: (RuleItem item) {
          // todo 同步
          // controller.saveRules();
          ruleDao.updateRule(item.toRule());
          controller.update();
        },
        onItemTap: (RuleItem item) {
          controller.selectedItem.value = item;
          if (appConfig.isSmallScreen) {
            Get.to(_buildRuleDetail());
          }
        },
        onItemAdd: (RuleItem newRule) {
          controller.rules.add(newRule);
          controller.selectedItem.value = newRule;
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
              if (old.id == item.id) {
                item.version++;
                late final Future<int> saveFuture;
                if(item.version == 1){
                  saveFuture = ruleDao.add(item.toRule());
                }else{
                  saveFuture = ruleDao.updateRule(item.toRule());
                }
                saveFuture.then((cnt){
                  if(cnt == 0){
                    Global.showSnackBarErr(text: TranslationKey.saveFailed.tr, context: Get.context!);
                    // controller.rules.assignAll([...controller.rules]);
                  }else{
                    Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: Get.context!);
                    controller.rules[i] = item;
                  }
                });
                break;
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appConfig.isSmallScreen) {
      return _buildRuleList();
    }
    return Container(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleList(),
          Expanded(
            child: _buildRuleDetail(),
          ),
        ],
      ),
    );
    // var view = MultiSplitView(
    //   controller: controller.splitViewController,
    //   axis: Axis.horizontal,
    //   pushDividers: false,
    //   builder: (BuildContext context, Area area) {
    //     if (area.index == 0) {
    //       return Container();
    //     }
    //     return Container();
    //   },
    // );
    // return MultiSplitViewTheme(
    //   data: MultiSplitViewThemeData(
    //     dividerThickness: 2,
    //     dividerPainter: DividerPainters.background(color: Colors.blue),
    //   ),
    //   child: view,
    // );
  }
}
