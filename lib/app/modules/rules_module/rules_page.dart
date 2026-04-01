library rules;

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/views/rules/rule_lib_detail.dart';
import 'package:clipshare/app/modules/views/rules/rule_detail.dart';
import 'package:clipshare/app/modules/views/rules/rule_list_view.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesPage extends GetView<RulesController> {
  RulesPage({super.key});

  static const logTag = 'RulesPage';
  final appConfig = Get.find<ConfigService>();
  final ruleDao = Get.find<DbService>().ruleDao;
  final libDao = Get.find<DbService>().ruleLibDao;
  final opRecordDao = Get.find<DbService>().opRecordDao;

  ///返回true则放弃
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
        luaLibs: controller.ruleLibs.value,
        disableRulesDrag: controller.activeItemChanged.value,
        onRuleDragged: () {
          controller.saveRules();
        },
        onRuleItemChanged: (RuleItem item) {
          controller.saveRules();
        },
        onRuleItemTap: (RuleItem item) async {
          final isCurrent = item.id == controller.selectedRuleItem.value?.id;
          if (isCurrent && !appConfig.isSmallScreen) {
            return false;
          }
          if (await _abortAskDialog(context)) {
            return false;
          }
          controller.selectedRuleItem.value = item;
          controller.selectedLuaLibItem.value = null;
          if (appConfig.isSmallScreen) {
            Get.to(_buildRuleDetail());
          }
          return true;
        },
        onRuleItemAdd: (RuleItem newRule) async {
          if (await _abortAskDialog(context)) {
            return;
          }
          controller.rules.add(newRule);
          controller.selectedRuleItem.value = newRule;
          controller.selectedLuaLibItem.value = null;
        },
        onRuleItemRemove: (Set<int> ids) async {
          final loading = Global.showLoadingDialog(
            context: context,
            loadingText: TranslationKey.deleting.tr,
          );
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
              //同步数据
              await opRecordDao.deleteByDataWithCascade(rule.id.toString());
              await opRecordDao.add(OperationRecord.fromSimple(Module.rule, OpMethod.delete, rule.id));
            }
          }
          if (replayItems.isNotEmpty) {
            controller.rules.addAll(replayItems);
            controller.rules.sort();
          }
          controller.saveRules();
          await loading.close();
          Global.showSnackBarSuc(
            text: TranslationKey.deleteSuccess.tr,
            context: context,
          );
        },
        onLuaLibItemTap: (RuleLib item) async {
          final isCurrent = item.libName == controller.selectedLuaLibItem.value?.libName;
          if (isCurrent && !appConfig.isSmallScreen) {
            return false;
          }
          if (await _abortAskDialog(context)) {
            return false;
          }
          controller.selectedLuaLibItem.value = item;
          controller.selectedRuleItem.value = null;
          if (appConfig.isSmallScreen) {
            Get.to(_buildLibDetail());
          }
          return Future.value(false);
        },
        onLuaLibItemAdd: (RuleLib value) async {
          if (await _abortAskDialog(context)) {
            return;
          }
          controller.ruleLibs.add(value);
          controller.selectedLuaLibItem.value = value;
          controller.selectedRuleItem.value = null;
        },
        onLuaLibItemRemove: (RuleLib lib) async {
          if (lib.isNewData) {
            controller.ruleLibs.removeWhere((e) => e.libName == lib.libName);
            Global.showSnackBarSuc(text: TranslationKey.deleteSuccess.tr, context: context);
            controller.selectedLuaLibItem.value = null;
            return;
          }
          final result = (await libDao.remove(lib.libName) ?? 0) > 0;
          if (result) {
            controller.ruleLibs.removeWhere((e) => e.libName == lib.libName);
            if (lib.libName == controller.selectedLuaLibItem.value?.libName) {
              controller.selectedLuaLibItem.value = null;
            }
            //同步数据
            await opRecordDao.deleteByDataWithCascade(lib.libName);
            await opRecordDao.add(OperationRecord.fromSimple(Module.ruleLib, OpMethod.delete, lib.libName));
            Global.showSnackBarSuc(text: TranslationKey.deleteSuccess.tr, context: context);
          } else {
            Global.showSnackBarSuc(text: TranslationKey.deletionFailed.tr, context: context);
          }
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
          rule: controller.selectedRuleItem.value,
          onSaveClicked: (item) {
            for (var i = 0; i < controller.rules.length; i++) {
              var old = controller.rules[i];
              if (old.id != item.id) {
                continue;
              }

              item.version = DateTime.now().yyyyMMddHHmmss;
              late final Future<int> saveFuture;
              final newRule = item.toRule();
              if (item.isNewData) {
                item.isNewData = false;
                saveFuture = ruleDao.addRule(newRule);
              } else {
                saveFuture = ruleDao.updateRule(newRule);
              }
              saveFuture
                  .then((cnt) async {
                    if (cnt == 0) {
                      Global.showSnackBarErr(
                        text: TranslationKey.saveFailed.tr,
                        context: Get.context!,
                      );
                    } else {
                      Global.showSnackBarSuc(
                        text: TranslationKey.saveSuccess.tr,
                        context: Get.context!,
                      );
                      controller.rules[i] = item;
                      controller.loadLuaUserFunc(
                        item.name,
                        item.script.content,
                        hash: item.id.toString(),
                      );
                      //同步数据
                      await opRecordDao.deleteByDataWithCascade(newRule.id.toString());
                      await opRecordDao.addAndNotify(OperationRecord.fromSimple(Module.rule, OpMethod.add, newRule.id));
                    }
                  })
                  .catchError((err, stack) {
                    Log.error(logTag, err, stack);
                    Global.showSnackBarErr(
                      text: TranslationKey.saveFailed.tr,
                      context: Get.context!,
                    );
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

  Widget _buildLibDetail() {
    return Padding(
      padding: 5.insetR,
      child: Obx(
        () {
          final lib = controller.selectedLuaLibItem.value;
          if (lib == null) {
            return EmptyContent();
          }
          return LuaLibDetail(
            lib: lib,
            onSaveClicked: (oldValue, newValue) {
              //todo
              for (var i = 0; i < controller.ruleLibs.length; i++) {
                var old = controller.ruleLibs[i];
                if (old.libName != oldValue.libName) {
                  continue;
                }
                newValue.version = DateTime.now().yyyyMMddHHmmss;
                late final Future<int> saveFuture;
                if (newValue.isNewData) {
                  newValue.isNewData = false;
                  saveFuture = libDao.addLib(newValue);
                } else {
                  saveFuture = libDao.updateLib(newValue);
                }
                saveFuture
                    .then((cnt) async {
                      if (cnt == 0) {
                        Global.showSnackBarErr(
                          text: TranslationKey.saveFailed.tr,
                          context: Get.context!,
                        );
                      } else {
                        Global.showSnackBarSuc(
                          text: TranslationKey.saveSuccess.tr,
                          context: Get.context!,
                        );
                        controller.ruleLibs[i] = newValue;
                        controller.selectedLuaLibItem.value = newValue;
                        //加载到全局函数
                        final result = controller.loadLuaLib(newValue);
                        Log.debug(logTag, "load lib(${lib.libName}): $result");
                        //同步数据
                        await opRecordDao.deleteByDataWithCascade(lib.libName);
                        await opRecordDao.addAndNotify(OperationRecord.fromSimple(Module.ruleLib, OpMethod.add, lib.libName));
                      }
                    })
                    .catchError((err, stack) {
                      Log.error(logTag, err, stack);
                      Global.showSnackBarErr(
                        text: TranslationKey.saveFailed.tr,
                        context: Get.context!,
                      );
                    });
                break;
              }
            },
            onSaveStatusChanged: (status) {
              controller.activeItemChanged.value = status;
            },
          );
        },
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
            child: Obx(() {
              final showRuleDetail = controller.selectedRuleItem.value != null;
              return showRuleDetail ? _buildRuleDetail() : _buildLibDetail();
            }),
          ),
        ],
      ),
    );
  }
}
