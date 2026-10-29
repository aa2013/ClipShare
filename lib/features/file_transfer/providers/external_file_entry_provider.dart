import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/platform/android/android_external_file_receive_provider.dart';
import 'package:clipshare/features/file_transfer/providers/send_compose_provider.dart';
import 'package:clipshare/features/file_transfer/utils/pending_file_resolver.dart';
import 'package:clipshare/features/home/providers/home_page_index_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_file_entry_provider.g.dart';

@Riverpod(keepAlive: true)
class ExternalFileEntryNotifier extends _$ExternalFileEntryNotifier {
  static const tag = 'ExternalFileEntryNotifier';

  AndroidExternalFileReceiveNotifier get _receiver => ref.read(androidExternalFileReceiveProvider.notifier);

  SendComposeNotifier get _sendCompose => ref.read(sendComposeProvider.notifier);

  HomePageIndexNotifier get _homePageIndex => ref.read(homePageIndexProvider.notifier);

  @override
  void build() {
    unawaited(_consume());
  }

  /// 消费外部文件事件批次，解析后送入发送编排并打开首页发送遮罩
  Future<void> _consume() async {
    final events = _receiver.events;
    await for (final event in events) {
      try {
        await _forward(event.files);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 解析外部文件并进入待发送流程
  Future<void> _forward(List<DropItem> files) async {
    final result = await resolvePendingFiles(files);
    if (result.failedCount > 0) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        snackbar.warn(context, TranslationKey.failedToLoad.tr);
      }
    }
    if (result.files.isEmpty) {
      return;
    }
    _sendCompose.addFiles(result.files);
    _homePageIndex.set(fileTransferPageIndex);
    _sendCompose.openOverlay();
  }
}
