import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:flutter_screenshot_detect/flutter_screenshot_detect.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

part 'screenshot_detect_provider.g.dart';

@Riverpod(keepAlive: true)
class ScreenshotDetectNotifier extends _$ScreenshotDetectNotifier {
  static const tag = 'ScreenshotDetectNotifier';
  var _detector = FlutterScreenshotDetect();
  String? _lastScreenshotContent;

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  SyncSettings get _syncSettings => ref.read(syncSettingsProvider).requireValue;

  Snowflake get _idProvider => ref.read(idProvider);

  AppPaths get _appPaths => ref.read(appPathsProvider).requireValue;

  HistoryRecorderNotifier get _historyRecorder => ref.read(historyRecorderProvider.notifier);

  @override
  void build() {}

  void startListenScreenshot() {
    if (!isAndroid) {
      return;
    }
    if (!_syncSettings.autoCopyImageAfterScreenShot) {
      return;
    }
    stopListenScreenshot();
    _detector = FlutterScreenshotDetect();
    _detector.startListening((event) async {
      if (event.path == null || _lastScreenshotContent == event.path) {
        return;
      }
      _lastScreenshotContent = event.path;
      try {
        await _detectScreenShotFile(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    });
  }

  void _onScreenShotDetected(String path) {
    _historyRecorder.emitRaw(
      RawHistoryEvent(
        history: simpleHistory(ref, .image, path),
        sync: false,
        source: null,
      ),
    );
  }

  Future<void> _detectScreenShotFile(FlutterScreenshotEvent event) async {
    await Future.delayed(500.ms);
    final uriFileInfo = await uriFileReader.getFileInfoFromUri(event.path!);
    logger.debug(tag, 'content uri: ${event.path!}');
    var realPath = uriFileInfo?.path;
    logger.debug(tag, 'realPath: $realPath');
    bool checkLatestImage = false;
    if (realPath == null) {
      logger.debug(
        tag,
        'real path is null, attempt to get latest image path',
      );
      try {
        checkLatestImage = true;
        final latestImagePath = await _androidChannel.getLatestImagePath();
        if (latestImagePath == null) {
          logger.warn(tag, 'latest image path is null');
          return;
        }
        logger.debug(tag, 'latest image path is $latestImagePath');
        realPath = latestImagePath;
      } catch (e) {
        return;
      }
    }
    final screenshotFile = File(realPath);
    final lastModified = screenshotFile.lastModifiedSync();
    final now = DateTime.now();
    final diffMs = now.difference(lastModified).inMilliseconds;
    logger.debug(
      tag,
      'file lastModifiedTime $lastModified. diff: $diffMs ms',
    );
    if (diffMs > 3000 && checkLatestImage) {
      //最新图片的修改时间与当前时间差距超过3s，忽略
      logger.debug(tag, '$diffMs ms More than 3 seconds.');
      return;
    }
    bool isScreenShot = false;
    for (var screenshotKey in screenshotKeywords) {
      screenshotKey = screenshotKey.toLowerCase();
      if (realPath.toLowerCase().contains(screenshotKey)) {
        isScreenShot = true;
        break;
      }
    }
    if (!isScreenShot) {
      return;
    }
    var copySuccess = false;
    try {
      final newFilePath = await uriFileReader.copyFileFromUri(event.path!, _appPaths.cachePath);
      logger.debug(tag, 'ScreenshotDetect: $realPath');
      if (newFilePath != null) {
        _onScreenShotDetected(newFilePath);
        copySuccess = true;
      } else {
        logger.warn(tag, 'Copy screenshot file failed!');
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    if (copySuccess) {
      return;
    }
    //尝试复制源文件
    var newPath = '${_appPaths.cachePath}/${_idProvider.nextIdStr()}.jpg';
    final result = await clipboardManager.executePrivilegedCommand('cp ${screenshotFile.absolute.path} $newPath && echo 0');
    if (result == '0') {
      _onScreenShotDetected(newPath);
      logger.debug(tag, 'attempt copy origin file via command success');
    } else {
      logger.debug(tag, 'attempt copy origin file via command failed: $result');
      //源文件复制失败，判断是否是pending文件
      if (screenshotFile.fileName.startsWith('.pending-')) {
        final newFileName = screenshotFile.fileName.split('-').sublist(2).join('-');
        final path = p.join(screenshotFile.parent.absolute.path, newFileName);
        logger.debug(tag, 'newPath = $path');
        var retryCnt = 0;
        while (retryCnt < 5) {
          logger.debug(tag, 'retry ${retryCnt + 1} times..');
          final exists = await File(path).exists();
          //尝试直接判断保存的文件是否存在
          if (exists) {
            _onScreenShotDetected(path);
          } else {
            //尝试提权复制
            final result = await clipboardManager.executePrivilegedCommand('cp $path $newPath && echo 0');
            if (result == '0') {
              logger.debug(tag, 'attempt copy file via command success');
              _onScreenShotDetected(path);
              break;
            } else {
              logger.debug(tag, 'attempt copy file via command failed: $result');
            }
          }
          await Future.delayed(2.s);
          retryCnt++;
        }
      }
    }
  }

  void stopListenScreenshot() {
    _detector.dispose();
  }
}
