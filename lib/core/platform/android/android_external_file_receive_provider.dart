import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/android/events/external_files_event.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/drop/my_drop_item.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_handler/share_handler.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

part 'android_external_file_receive_provider.g.dart';

@Riverpod(keepAlive: true)
class AndroidExternalFileReceiveNotifier extends _$AndroidExternalFileReceiveNotifier {
  static const tag = 'AndroidExternalFileReceiveNotifier';

  final _events = StreamController<ExternalFilesEvent>.broadcast();

  Stream<ExternalFilesEvent> get events => _events.stream;

  @override
  void build() {
    ref.onDispose(_events.close);
    unawaited(_listenShareMedia());
  }

  /// 消费系统分享事件流转发；冷启动的分享意图由插件缓存，订阅时回放
  Future<void> _listenShareMedia() async {
    if (!isAndroid) {
      return;
    }
    await for (final media in ShareHandlerPlatform.instance.sharedMediaStream) {
      try {
        await _handleSharedMedia(media);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 分享内容归一化：附件走文件集合，纯文本走 uri 解析，均无则提示不支持
  Future<void> _handleSharedMedia(SharedMedia media) async {
    logger.info(tag, 'ShareMedia: ${media.attachments}, content: ${media.content}');
    final attachments = media.attachments;
    if (attachments != null) {
      final files = attachments
          .where((attachment) => attachment != null)
          .map((attachment) => attachment!.path)
          .map((path) => DropItemFile(path))
          .toList(growable: false);
      _emit(files);
      return;
    }
    final content = media.content;
    if (content.isBlank != true) {
      await handleIncomingUri(content!);
      return;
    }
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      unawaited(dialogManager.tips(context, text: TranslationKey.saveFileNotSupportDialogText.tr));
    }
  }

  /// 统一处理以 Uri 形式进入应用的外部文件，并复用现有文件信息解析能力。
  Future<void> handleIncomingUri(String uri) async {
    final fileInfo = await uriFileReader.getFileInfoFromUri(uri);
    if (fileInfo == null) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        snackbar.warn(context, TranslationKey.failedToLoad.tr);
      }
      logger.debug(tag, '未从uri中获取到文件名称和大小：uri = $uri');
      return;
    }
    final fileName = fileInfo.fileName;
    final size = fileInfo.size;
    logger.info(tag, 'ShareMedia fileName $fileName, size $size');
    _emit([DropItemFileUri(uri, fileName, size)]);
  }

  /// 统一处理直接可落地为本地路径的外部文件集合，空集合直接忽略
  void _emit(List<DropItem> files) {
    logger.debug(tag, files);
    if (files.isEmpty) {
      return;
    }
    _events.add(ExternalFilesEvent(files));
  }
}
