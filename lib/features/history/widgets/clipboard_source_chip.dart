import 'dart:async';

import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/device/device_provider.dart';
import 'package:clipshare/core/history/history_event.dart';
import 'package:clipshare/core/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/app_selection/app_selection_entry.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_icon.dart';

/// 历史记录来源入口：未设置来源时展示添加按钮，已设置时展示来源图标。
class ClipboardSourceChip extends ConsumerWidget {
  final History history;
  final Function(AppInfo appInfo) onAdded;
  final Function() onDeleted;

  const ClipboardSourceChip({
    super.key,
    required this.history,
    required this.onAdded,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.source == null) {
      return RoundedChip(
        onPressed: () {
          unawaited(_openSourceSelection(context, ref));
        },
        avatar: const Icon(Icons.add),
        label: Text(
          TranslationKey.source.tr,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
    return AppIcon(
      appId: history.source!,
      onDeleteClicked: () {
        unawaited(_confirmClearSource(context, ref));
      },
    );
  }

  /// 打开来源选择页，仅列出来源库中本机设备展示的应用；选中后写入来源并通知列表刷新。
  Future<void> _openSourceSelection(BuildContext context, WidgetRef ref) async {
    final deviceState = ref.read(deviceProvider).value;
    final selfId = ref.read(localDeviceInfoProvider).value?.baseDeviceInfo.id ?? '';
    await showAppSelection(
      context,
      AppSelectionRouteArgs(
        limit: 1,
        loadDeviceName: (devId) => deviceState?.getName(devId) ?? TranslationKey.unknown.tr,
        loadAppInfos: () async {
          final sourceState = ref.read(clipboardSourceProvider).value;
          final list = (sourceState?.appInfos ?? <AppInfo>[])
              .where((item) => item.devId == selfId)
              .map((item) => LocalAppInfo.fromAppInfo(item, false))
              .toList();
          return list;
        },
        onSelectedDone: (selected) async {
          if (selected.isEmpty) {
            return;
          }
          final appInfo = selected[0];
          final id = history.id;
          final db = await ref.read(appDbProvider.future);
          final self = ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;
          final success = await db.historyDao.updateHistorySourceAndNotify(
            id,
            appInfo.appId,
            ref.read(idProvider),
            self,
          );
          if (!context.mounted) return;
          if (success) {
            // 同步更新列表内存中的来源并通知刷新
            final updated = history.copyWith(source: Value(appInfo.appId));
            ref.read(historiesProvider.notifier).addDelta(
                  HistoryDeltaEvent(
                    history: updated,
                    operation: OpMethod.update,
                  ),
                );
            snackbar.success(context, TranslationKey.updateSuccess.tr);
            onAdded(appInfo);
          } else {
            snackbar.warn(context, TranslationKey.updateFailed.tr);
          }
        },
      ),
    );
  }

  /// 弹出清除来源确认框。
  Future<void> _confirmClearSource(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await dialogManager.tips(
      context,
      text: TranslationKey.clearSourceConfirmText.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () {
            unawaited(_clearSource(context, ref));
          },
        ),
      ),
    );
  }

  /// 清除历史来源，成功后清理未使用来源信息并通知列表刷新。
  Future<void> _clearSource(BuildContext context, WidgetRef ref) async {
    final id = history.id;
    final db = await ref.read(appDbProvider.future);
    final self = ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;
    final success = await db.historyDao.clearHistorySourceAndNotify(
      id,
      ref.read(idProvider),
      self,
    );
    if (success) {
      ref.read(historiesProvider.notifier)
          .addDelta(
            HistoryDeltaEvent(
              history: history.copyWith(source: const Value<String?>(null)),
              operation: OpMethod.update,
            ),
          );
      // 移除未使用的剪贴板来源信息
      await ref.read(clipboardSourceProvider.notifier).removeNotUsed();
      if (context.mounted) {
        snackbar.success(context, TranslationKey.clearSuccess.tr);
      }
      onDeleted();
    } else {
      if (context.mounted) {
        snackbar.warn(context, TranslationKey.clearFailed.tr);
      }
    }
  }
}