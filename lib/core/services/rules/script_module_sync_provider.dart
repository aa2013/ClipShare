import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'script_module_sync_provider.g.dart';

/// 脚本模块同步处理器。
@Riverpod(keepAlive: true)
class ScriptModuleSyncNotifier extends _$ScriptModuleSyncNotifier {
  static const tag = 'ScriptModuleSyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  ScriptModuleDao get _scriptModuleDao => ref.read(appDbProvider).requireValue.scriptModuleDao;

  RulesExecutorNotifier get _rulesExecutor => ref.read(rulesExecutorProvider.notifier);

  @override
  void build() {
    unawaited(_listenSyncEvents());
  }

  /// 监听脚本模块同步事件，应用成功后回传确认。
  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        if (event is! ScriptModuleSyncEvent) {
          continue;
        }
        if (!await _apply(event)) {
          continue;
        }
        _syncNotifier.emitPendingAckFor(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 处理脚本模块同步事件
  Future<bool> _apply(ScriptModuleSyncEvent event) async {
    final module = event.scriptModule;
    switch (event.method) {
      case .add:
      case .update:
        final local = await _scriptModuleDao.getByName(module.moduleName);
        if (local != null && local.version >= module.version) {
          //本地版本比同步过来的新，强制忽略避免后续无意义补推
          return true;
        }
        final success = local == null
            ? await _scriptModuleDao.addModule(module) > 0
            : await _scriptModuleDao.updateModule(module) > 0;
        if (success) {
          _rulesExecutor.addOrUpdateRuleLib(module);
        }
        return success;
      case .delete:
        final local = await _scriptModuleDao.getByName(module.moduleName);
        if (local == null) {
          return true;
        }
        final success = (await _scriptModuleDao.remove(module.moduleName) ?? 0) > 0;
        if (success) {
          _rulesExecutor.removeScriptModule(module.moduleName);
        }
        return success;
      case .unknown:
        return false;
    }
  }
}
