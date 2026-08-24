import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/rules/rules_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/consumer_wrapper.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/rules/pages/rule_list_view.dart';
import 'package:clipshare/features/rules/pages/script_module_detail.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'rule_detail.dart';

class RulesPage extends ConsumerWidget {
  static const tag = 'RulesPage';

  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isCompactScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(TranslationKey.rulesManagement.tr),
            ],
          ),
        ),
        body: _buildRuleList(context),
      );
    }
    return Container(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleList(context),
          Expanded(
            child: consumerWrapper((context, ref) {
              final selectedRuleItem = ref.watch(rulesExecutorProvider.select((asyncValue) {
                return asyncValue.value?.selectedRuleItem;
              }),);
              final selectedLuaModuleItem = ref.watch(rulesExecutorProvider.select((asyncValue) {
                return asyncValue.value?.selectedLuaModuleItem;
              }),);
              if (selectedRuleItem != null) {
                return Padding(
                  padding: 5.insetR,
                  child: const RuleDetail(),
                );
              }
              if (selectedLuaModuleItem != null) {
                return Padding(
                  padding: 5.insetR,
                  child: const ScriptModuleDetail(),
                );
              }
              return const EmptyContent();
            }),
          ),
        ],
      ),
    );
  }

  ///返回true则放弃
  Future<bool> _abortAskDialog(BuildContext context, WidgetRef ref) async {
    var abort = false;
    final rules = ref.read(rulesExecutorProvider).requireValue;
    if (rules.activeItemChanged) {
      DialogController? dialog;
      dialog = await dialogManager.tips(
        context,
        autoDismiss: false,
        text: TranslationKey.rulesPageUnsavedChangesConfirm.tr,
        actions: DialogActions(
          cancel: DialogAction(onPressed: () {
            abort = true;
            dialog?.close();
          }),
          confirm: DialogAction(onPressed: () {
            dialog?.close();
          }),
        ),
      );
      await dialog?.future;
    }
    return abort;
  }

  Widget _buildRuleList(BuildContext context) {
    final listView = Consumer(builder: (context, ref, child) {
      final ruleState = ref.watch(rulesExecutorProvider).requireValue;
      final rulesExecutor = ref.watch(rulesExecutorProvider.notifier);

      final snowflake = ref.read(idProvider);
      final baseDevInfo = ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

      final ruleDao = ref.read(appDbProvider).requireValue.ruleDao;
      final scriptModuleDao = ref.read(appDbProvider).requireValue.scriptModuleDao;
      final opRecordDao = ref.read(appDbProvider).requireValue.operationRecordDao;

      return RuleListView(
        rules: ruleState.rules,
        scriptModules: ruleState.scriptModules,
        activeLuaModuleItem: ruleState.selectedLuaModuleItem,
        activeRuleItem: ruleState.selectedRuleItem,
        disableRulesDrag: ruleState.activeItemChanged,
        onRuleDragged: () {
          rulesExecutor.saveRules();
        },
        onRuleItemChanged: (RuleItem item) {
          rulesExecutor.saveRules();
        },
        onRuleItemTap: (RuleItem item) async {
          final isCurrent = item.id == ruleState.selectedRuleItem?.id;
          if (isCurrent && !context.isCompactScreen) {
            return false;
          }
          if (await _abortAskDialog(context, ref)) {
            return false;
          }
          //如果是新规则，直接丢弃
          if (ruleState.selectedRuleItem?.isNewData ?? false) {
            ruleState.rules.removeWhere((e) =>
            e.id == ruleState.selectedRuleItem?.id);
          }
          //如果是新的，直接丢弃
          if (ruleState.selectedLuaModuleItem?.isNewData ?? false) {
            ruleState.scriptModules.removeWhere((e) => e.moduleName == ruleState.selectedLuaModuleItem?.moduleName);
          }
          rulesExecutor.updateSelectedRuleItem(item.copy());
          rulesExecutor.updateSelectedScriptModule(null);
          if (context.mounted && context.isCompactScreen) {
            unawaited(context.pushNamed(AppRoutes.ruleDetail.name));
          }
          return true;
        },
        onRuleItemAdd: (RuleItem newRule) async {
          if (await _abortAskDialog(context, ref)) {
            return;
          }
          //如果是新规则，直接丢弃
          if (ruleState.selectedRuleItem?.isNewData ?? false) {
            ruleState.rules.removeWhere((e) =>
            e.id == ruleState.selectedRuleItem?.id);
          }
          //如果是新的，直接丢弃
          if (ruleState.selectedLuaModuleItem?.isNewData ?? false) {
            ruleState.scriptModules.removeWhere((e) =>
            e.moduleName ==
                ruleState.selectedLuaModuleItem?.moduleName);
          }
          ruleState.rules.add(newRule);
          rulesExecutor.updateSelectedRuleItem(newRule);
          rulesExecutor.updateSelectedScriptModule(null);
          if (context.mounted && context.isCompactScreen) {
            unawaited(context.pushNamed(AppRoutes.ruleDetail.name));
          }
        },
        onRuleItemRemove: (Set<int> ids) async {
          final loading = dialogManager.loading(
            context,
            loadingText: TranslationKey.deleting.tr,
          );
          final List<RuleItem> items = [];
          ruleState.rules.removeWhere((rule) {
            if (!ids.contains(rule.id)) {
              return false;
            }
            //未保存的直接删除
            if (rule.version <= 0 || rule.isNewData) {
              if (ruleState.selectedRuleItem?.id == rule.id) {
                rulesExecutor.updateSelectedRuleItem(null);
                rulesExecutor.updateActiveItemChanged(false);
              }
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
              await opRecordDao.addAndNotify(newOperationRecord(
                  snowflake,
                  baseDevInfo,
                  Module.rule,
                  OpMethod.delete,
                  rule.id,
              ));
            }
          }
          if (replayItems.isNotEmpty) {
            ruleState.rules.addAll(replayItems);
            ruleState.rules.sort();
          }
          await rulesExecutor.saveRules();
          await loading.close();
          if(context.mounted) {
            snackbar.success(
              context,
              TranslationKey.deleteSuccess.tr,
            );
          }
        },
        onScriptModuleItemTap: (ScriptModule item) async {
          final isCurrent = item.moduleName == ruleState.selectedLuaModuleItem?.moduleName;
          if (isCurrent && !context.isCompactScreen) {
            return false;
          }
          if (await _abortAskDialog(context, ref)) {
            return false;
          }
          //如果是新规则，直接丢弃
          if (ruleState.selectedRuleItem?.isNewData ?? false) {
            ruleState.rules.removeWhere((e) =>
            e.id == ruleState.selectedRuleItem?.id);
          }
          //如果是新的，直接丢弃
          if (ruleState.selectedLuaModuleItem?.isNewData ?? false) {
            ruleState.scriptModules.removeWhere((e) =>
            e.moduleName == ruleState.selectedLuaModuleItem?.moduleName);
          }
          rulesExecutor.updateSelectedRuleItem(null);
          rulesExecutor.updateSelectedScriptModule(item.copy());
          if (context.mounted && context.isCompactScreen) {
            unawaited(context.pushNamed(AppRoutes.scriptModuleDetail.name));
          }
          return true;
        },
        onScriptModuleItemAdd: (ScriptModule value) async {
          if (await _abortAskDialog(context, ref)) {
            return;
          }
          //如果是新规则，直接丢弃
          if (ruleState.selectedRuleItem?.isNewData ?? false) {
            ruleState.rules.removeWhere((e) =>
            e.id == ruleState.selectedRuleItem?.id);
          }
          //如果是新的，直接丢弃
          if (ruleState.selectedLuaModuleItem?.isNewData ?? false) {
            ruleState.scriptModules.removeWhere((e) =>
            e.moduleName ==
                ruleState.selectedLuaModuleItem?.moduleName);
          }
          ruleState.scriptModules.add(value);
          rulesExecutor.updateSelectedRuleItem(null);
          rulesExecutor.updateSelectedScriptModule(value);
          if (context.mounted && context.isCompactScreen) {
            unawaited(context.pushNamed(AppRoutes.scriptModuleDetail.name));
          }
        },
        onScriptModuleItemRemove: (ScriptModule lib) async {
          if (lib.isNewData) {
            ruleState.scriptModules.removeWhere((e) =>
            e.moduleName == lib.moduleName);
            snackbar.success(context, TranslationKey.deleteSuccess.tr);
            rulesExecutor.updateSelectedScriptModule(null);
            rulesExecutor.updateActiveItemChanged(false);
            return;
          }
          final result = (await scriptModuleDao.remove(lib.moduleName) ?? 0) >
              0;
          if (result) {
            ruleState.scriptModules.removeWhere((e) =>
            e.moduleName == lib.moduleName);
            if (lib.moduleName == ruleState.selectedLuaModuleItem?.moduleName) {
              rulesExecutor.updateSelectedScriptModule(null);
              rulesExecutor.updateActiveItemChanged(false);
            }
            //同步数据
            await opRecordDao.deleteByDataWithCascade(lib.moduleName);
            await opRecordDao.addAndNotify(
              newOperationRecord(
                snowflake,
                baseDevInfo,
                Module.scriptModule,
                OpMethod.delete,
                lib.moduleName,
              ),
            );
            if (context.mounted) {
              snackbar.success(context, TranslationKey.deleteSuccess.tr);
            }
          } else {
            if (context.mounted) {
              snackbar.error(context, TranslationKey.deletionFailed.tr);
            }
          }
        },
      );
    },);
    if (context.isCompactScreen) {
      return listView;
    }
    return SizedBox(
      width: 250,
      child: listView,
    );
  }
}
