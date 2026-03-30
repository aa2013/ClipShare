library rules;

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/views/rules/lib_detail.dart';
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
  final libDao = Get.find<DbService>().luaLibDao;

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
        luaLibs: controller.luaLibs.value,
        disableRulesDrag: controller.activeItemChanged.value,
        onRuleDragged: () {
          // todo 同步
          controller.saveRules();
        },
        onRuleItemChanged: (RuleItem item) {
          // todo 同步
          controller.saveRules();
          // ruleDao.updateRule(item.toRule());
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
              //todo 同步数据
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
        onLuaLibItemTap: (LuaLib item) async {
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
        onLuaLibItemAdd: (LuaLib value) async {
          if (await _abortAskDialog(context)) {
            return;
          }
          controller.luaLibs.add(value);
          controller.selectedLuaLibItem.value = value;
          controller.selectedRuleItem.value = null;
        },
        onLuaLibItemRemove: (LuaLib lib) async {
          if (lib.isNewData) {
            controller.luaLibs.removeWhere((e) => e.libName == lib.libName);
            Global.showSnackBarSuc(text: TranslationKey.deleteSuccess.tr, context: context);
            controller.selectedLuaLibItem.value = null;
            return;
          }
          final result = (await libDao.remove(lib.libName) ?? 0) > 0;
          if (result) {
            controller.luaLibs.removeWhere((e) => e.libName == lib.libName);
            if (lib.libName == controller.selectedLuaLibItem.value?.libName) {
              controller.selectedLuaLibItem.value = null;
            }
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
              if (item.isNewData) {
                //todo 同步数据
                item.isNewData = false;
                saveFuture = ruleDao.addRule(item.toRule());
              } else {
                //todo 同步数据
                saveFuture = ruleDao.updateRule(item.toRule());
              }
              saveFuture
                  .then((cnt) {
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
              for (var i = 0; i < controller.luaLibs.length; i++) {
                var old = controller.luaLibs[i];
                if (old.libName != oldValue.libName) {
                  continue;
                }
                newValue.version = DateTime.now().yyyyMMddHHmmss;
                late final Future<int> saveFuture;
                if (newValue.isNewData) {
                  //todo 同步数据
                  newValue.isNewData = false;
                  saveFuture = libDao.addLib(newValue);
                } else {
                  //todo 同步数据
                  saveFuture = libDao.updateLib(newValue);
                }
                saveFuture
                    .then((cnt) {
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
                        controller.luaLibs[i] = newValue;
                        controller.selectedLuaLibItem.value = newValue;
                        //加载到全局函数
                        final result = controller.loadLuaLib(newValue);
                        Log.debug(logTag, "load lib(${lib.libName}): $result");
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
