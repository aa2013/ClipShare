import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/rule_dao.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rule_sync_provider.g.dart';

/// 规则同步处理器。
@Riverpod(keepAlive: true)
class RuleSyncNotifier extends _$RuleSyncNotifier {
  static const tag = 'RuleSyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  RuleDao get _ruleDao => ref.read(appDbProvider).requireValue.ruleDao;

  RulesExecutorNotifier get _rulesExecutor => ref.read(rulesExecutorProvider.notifier);

  @override
  void build() {
    unawaited(_listenSyncEvents());
  }

  /// 监听规则同步事件，应用成功后回传确认。
  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        if (event is! RuleSyncEvent) {
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

  /// 处理应用规则同步事件
  Future<bool> _apply(RuleSyncEvent event) async {
    final rule = event.rule;
    switch (event.method) {
      case .add:
      case .update:
        final local = await _ruleDao.getById(rule.id);
        if (local != null && local.version >= rule.version) {
          //本地版本比同步过来的新，强制忽略避免后续无意义补推
          return true;
        }
        final success = local == null
            ? await _ruleDao.addRule(rule) > 0
            : await _ruleDao.updateRule(rule) > 0;
        if (success) {
          _rulesExecutor.addOrUpdateRule(rule);
        }
        return success;
      case .delete:
        final local = await _ruleDao.getById(rule.id);
        if (local == null) {
          return true;
        }
        final success = (await _ruleDao.remove(rule.id) ?? 0) > 0;
        if (success) {
          _rulesExecutor.removeRule(rule.id);
        }
        return success;
      case .unknown:
        return false;
    }
  }
}
