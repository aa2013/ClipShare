import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/exceptions/fetch_update_logs_exception.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/models/update_log.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/single_group_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zip_flutter/zip_flutter.dart';

part 'app_update_info_provider.g.dart';

///应用更新检查
@Riverpod(keepAlive: true)
class AppUpdateInfoNotifier extends _$AppUpdateInfoNotifier {
  static const tag = 'AppUpdateInfoNotifier';

  //各桌面平台可用的安装包类型
  static final _installerTypes = <TargetPlatform, List<String>>{
    TargetPlatform.windows: ['.exe', '.zip'],
    TargetPlatform.linux: ['.deb', '.rpm', '.AppImage'],
  };
  static const String _archArm32 = 'arm';
  static const String _archX64 = 'x64';
  static const String _defaultUpdateInfoFileName = 'version-info.json';

  //当前设备 CPU 架构
  static final String _currentArch = Abi.current().toString().split('_').last;

  //上次检测app更新的时间
  DateTime? _lastCheckUpdateTime;

  //应用更新设置
  AppUpdateSettings get _appUpdateSettings => ref.read(appUpdateSettingsProvider).requireValue;

  //当前应用版本
  AppVersion get _appVersion => ref.read(localDeviceInfoProvider).requireValue.appVersion;

  //更新文件下载目录
  String get _updateDownloadDirPath => ref.read(appPathsProvider).requireValue.updateDownloadFileDirPath;

  //配置表 DAO
  ConfigDao get _configDao => ref.read(appDbProvider).requireValue.configDao;

  //系统通知
  NotifyNotifier get _notifyNotifier => ref.read(notifyProvider.notifier);

  //当前界面语言
  Locale get _uiLocale => ref.read(uiLocaleProvider);

  @override
  Future<void> build() async {}

  /// 检查更新并在发现新版本时弹窗提示，返回是否发现了新版本。
  ///
  /// [forceCheck] 为 true 时忽略“跳过此版本”的记录
  /// [debounce] 为 true 时 6 小时内仅检查一次
  Future<bool> showUpdateInfo(
    BuildContext context, {
    bool forceCheck = false,
    bool debounce = false,
  }) async {
    final now = DateTime.now();
    if (_lastCheckUpdateTime != null && debounce) {
      final diffHours = now.difference(_lastCheckUpdateTime!).inHours;
      //检测间隔不能低于6h
      if (diffHours < 6) {
        return false;
      }
    }
    _lastCheckUpdateTime = now;
    //提前读取异步流程依赖，避免跨异步间隙访问 ref
    final appUpdateSettings = _appUpdateSettings;
    final updateDownloadFileDirPath = _updateDownloadDirPath;
    final notifyNotifier = _notifyNotifier;
    final logs = await fetchUpdateLogs();
    if (logs.isEmpty) {
      return false;
    }
    final latestVersionCode = logs.first.version.code;
    if (latestVersionCode == appUpdateSettings.ignoreUpdateVersion && !forceCheck) {
      return false;
    }
    if (!context.mounted) {
      return false;
    }
    String content = '';
    String latestVersion = '';
    for (var log in logs) {
      final version = log.version;
      if (latestVersion == '') {
        latestVersion = 'ClipShare-${version.name}_${version.code}';
      }
      content += '🏷️$version\n';
      content += '${log.desc}\n\n';
    }
    final pkgTypes = _installerTypes[defaultTargetPlatform] ?? [];
    Widget? customWidget;
    //当前选中的安装包类型
    final selectedType = ValueNotifier<String?>(null);
    if (pkgTypes.isNotEmpty) {
      selectedType.value = pkgTypes[0];
      customWidget = _buildAppInfoCustomWidget(context, selectedType, pkgTypes);
    }
    var downloadUrl = logs.first.downloadUrl;
    unawaited(
      dialogManager.tips(
        context,
        title: TranslationKey.newVersionDialogTitle.tr,
        text: content,
        maxWidth: 300,
        customWidget: customWidget,
        actions: DialogActions(
          neutral: DialogAction(
            text: TranslationKey.newVersionDialogSkipText.tr,
            onPressed: () {
              //写入数据库跳过更新的版本号
              _setIgnoreUpdateVersion(latestVersionCode);
            },
          ),
          cancel: const DialogAction(),
          confirm: DialogAction(
            text: TranslationKey.newVersionDialogOkText.tr,
            onPressed: () => _onDownloadClicked(
              context,
              selectedType,
              downloadUrl,
              latestVersion,
              updateDownloadFileDirPath,
            ),
          ),
        ),
      ),
    );
    const notifyKey = 'appUpdate';
    final notifyId = await notifyNotifier.notify(
      content: '${TranslationKey.newVersionAvailable.tr} ${logs.first.version}',
      key: notifyKey,
    );
    if (notifyId != null) {
      unawaited(
        Future.delayed(2.s, () {
          notifyNotifier.cancel(notifyKey, notifyId);
        }),
      );
    }
    return true;
  }

  Widget _buildAppInfoCustomWidget(BuildContext context, ValueNotifier<String?> selectedType, List<String> pkgTypes) {
    final theme = context.currentTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: 4.insetV,
          child: Text(
            TranslationKey.selectInstallerType.tr,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: selectedType,
          builder: (context, value, _) {
            return Wrap(
              spacing: 5,
              runSpacing: 5,
              children: pkgTypes
                  .map((pkgType) {
                    return SingleGroupChip(
                      text: pkgType,
                      isSelected: pkgType == value,
                      onTap: () {
                        selectedType.value = pkgType;
                      },
                    );
                  })
                  .cast<Widget>()
                  .toList(),
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: selectedType,
          builder: (context, value, _) {
            return Visibility(
              visible: value == '.zip',
              child: Container(
                margin: 5.insetT,
                child: Text(
                  TranslationKey.updateFromZipTips.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _onDownloadClicked(
    BuildContext context,
    ValueNotifier<String?> selectedType,
    String downloadUrl,
    String latestVersion,
    String updateDownloadFileDirPath,
  ) async {
    try {
      if (selectedType.value != null) {
        downloadUrl = _replaceUrlExtension(downloadUrl, selectedType.value!);
      }
      var fileName = Uri.parse(downloadUrl).path.replaceAll('\\', '/').split('/').last;
      var downPath = '';

      if (isAndroid) {
        //根据架构确定下载的安装包
        if (_currentArch == _archArm32) {
          downloadUrl = downloadUrl.replaceFirst('arm64-v8a', 'armeabi-v7a');
          fileName = fileName.replaceFirst('arm64-v8a', 'armeabi-v7a');
        } else if (_currentArch == _archX64) {
          downloadUrl = downloadUrl.replaceFirst('arm64-v8a', 'x86_64');
          fileName = fileName.replaceFirst('arm64-v8a', 'x86_64');
        }
        fileName = '${latestVersion}_$fileName';
      }
      downPath = '$updateDownloadFileDirPath/$fileName';
      await File(downPath).parent.create();
      //下载完成后是否打开所在目录
      final openFolderAfterDownload = ValueNotifier<bool>(isLinux || isMacOS);
      if (!context.mounted) {
        return;
      }
      dialogManager.downloading(
        context,
        url: downloadUrl,
        filePath: downPath,
        content: ValueListenableBuilder<bool>(
          valueListenable: openFolderAfterDownload,
          builder: (context, value, _) {
            return Column(
              children: [
                Text(fileName),
                const SizedBox(height: 5),
                CheckboxListTile(
                  value: value,
                  title: Text(TranslationKey.openPathAfterDownload.tr),
                  onChanged: (selected) {
                    openFolderAfterDownload.value = selected ?? false;
                  },
                ),
              ],
            );
          },
        ),
        onFinished: (success) async {
          if (success) {
            final updateFile = File(downPath);
            if (openFolderAfterDownload.value) {
              await updateFile.openPath();
            } else {
              if (selectedType.value == '.zip') {
                await _updateWindowsFromZip(updateFile);
              } else {
                await OpenFile.open(downPath);
              }
            }
          }
        },
        onError: (error, stack) async {
          if (!context.mounted) {
            return;
          }
          await dialogManager.tips(context, text: 'error $error,$stack');
        },
      );
    } catch (err, stack) {
      logger.error(tag, 'error: $err. $stack');
      if (!context.mounted) {
        return;
      }
      downloadUrl.askOpenUrl(context);
    }
  }

  /// 拉取远程更新日志并过滤出比当前版本新的记录。
  Future<List<UpdateLog>> fetchUpdateLogs() async {
    //提前读取更新信息地址与当前版本，避免请求后再访问 ref
    final updateInfoUrl = _buildUpdateInfoUrl();
    final currentVersion = _appVersion;
    try {
      final resp = await http.get(Uri.parse(updateInfoUrl));
      if (resp.statusCode != 200) {
        throw FetchUpdateLogsException(resp.statusCode.toString());
      }
      final updateLogs = List<UpdateLog>.empty(growable: true);
      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      final logs = body['logs'] as List<dynamic>;
      final String system;
      if (isMacOS) {
        system = 'MacOS';
      } else if (isIOS) {
        system = 'IOS';
      } else {
        //iOS = ios
        //macOS = macos
        system = Platform.operatingSystem;
      }

      for (var log in logs) {
        log['url'] = body['downloads'][system.upperFirst]['url'];
        final ul = UpdateLog.fromJson(log);
        final platform = ul.platform.toLowerCase();
        if ((platform != system.toLowerCase() && platform != 'all') || ul.version <= currentVersion) {
          continue;
        }
        updateLogs.add(ul);
      }
      updateLogs.sort((a, b) => b.version - a.version);
      return updateLogs;
    } catch (e) {
      final errorMsg = '检查update log的过程中出现异常\n错误: $e';
      logger.error(tag, errorMsg);
      throw FetchUpdateLogsException(errorMsg);
    }
  }

  /// 根据当前语言构造更新信息地址；中文沿用默认文件，非中文统一使用英文更新说明文件。
  String _buildUpdateInfoUrl() {
    final locale = _uiLocale;
    if (locale.languageCode.toLowerCase() == AppLanguage.zhCnLocale.languageCode) {
      return appUpdateInfoUrl;
    }
    return appUpdateInfoUrl.replaceFirst(_defaultUpdateInfoFileName, 'version-info.en.json');
  }

  /// 写入跳过更新的版本号并刷新更新设置。
  Future<void> _setIgnoreUpdateVersion(String versionCode) async {
    await _configDao.addOrUpdate(ConfigKey.ignoreUpdateVersion, versionCode);
    ref.invalidate(appUpdateSettingsProvider);
  }

  /// 替换下载地址中的文件扩展名。
  static String _replaceUrlExtension(String url, String newExtension) {
    assert(newExtension[0] == '.');
    // 找到最后一个 "." 的位置（文件名中的扩展名分隔符）
    int lastDotIndex = url.lastIndexOf('.');
    if (lastDotIndex == -1) {
      // 如果没有扩展名，直接附加
      return url + newExtension;
    }

    // 找到最后一个 "/" 的位置，确保 "." 是文件名的一部分而不是路径的一部分
    int lastSlashIndex = url.lastIndexOf('/');
    if (lastSlashIndex > lastDotIndex) {
      // 如果最后一个 "." 在最后一个 "/" 之前，说明没有扩展名
      return url + newExtension;
    }

    // 替换扩展名
    return url.substring(0, lastDotIndex) + newExtension;
  }

  /// 使用 zip 安装包自更新 Windows 应用：解压后启动批处理脚本并退出当前进程。
  static Future<void> _updateWindowsFromZip(File updateFile) async {
    logger.debug(tag, 'update zip file downloaded');
    final downDirPath = updateFile.parent.absolute.path;
    final updateFileExtractDirPath = p.join(downDirPath, 'temp').normalizePath;
    await Directory(updateFileExtractDirPath).create(recursive: true);
    logger.debug(tag, 'zip file extracting');
    //解压zip
    await ZipFile.openAndExtractAsync(updateFile.absolute.path, updateFileExtractDirPath);
    logger.debug(tag, 'zip file extracted');
    final execDirPath = File(Platform.resolvedExecutable).parent.absolute.path;
    final batFilePath = p.join(execDirPath, 'data', 'flutter_assets', 'assets', 'scripts', 'update_windows.bat').normalizePath;
    final process = await Process.start(
      'cmd',
      ['/c', batFilePath, pid.toString(), updateFileExtractDirPath],
      runInShell: true,
      mode: ProcessStartMode.detached,
      workingDirectory: execDirPath,
    );
    logger.debug(tag, 'Update process started (PID: ${process.pid})');
    await Future.delayed(1.s);
    logger.debug(tag, 'Exiting application, waiting for batch update...');
    exit(0);
  }
}
