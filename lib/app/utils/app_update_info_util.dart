import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/update_log.dart';
import 'package:clipshare/app/exceptions/fetch_update_logs_exception.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare/app/widgets/single_group_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:zip_flutter/zip_flutter.dart';
import 'package:path/path.dart' as p;

class AppUpdateInfoUtil {
  //上次检测app更新的时间
  static DateTime? _lastCheckUpdateTime;
  static const tag = "AppUpdateInfoUtil";
  static final _installerTypes = <TargetPlatform, List<String>>{
    TargetPlatform.windows: [".exe", ".zip"],
    TargetPlatform.linux: [".deb", ".AppImage", ".rpm"],
  };
  static const String _archArm32 = "arm";
  static const String _archArm64 = "arm64";
  static const String _archX86 = "ia32";
  static const String _archX64 = "x64";
  static final String _currentArch = Abi.current().toString().split("_").last;

  static Future<List<UpdateLog>> fetchUpdateLogs() async {
    try {
      final resp = await http.get(Uri.parse(Constants.appUpdateInfoUrl));
      if (resp.statusCode != 200) {
        throw FetchUpdateLogsException(resp.statusCode.toString());
      }
      final updateLogs = List<UpdateLog>.empty(growable: true);
      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      final logs = body["logs"] as List<dynamic>;
      final system = Platform.isMacOS ? "MacOS" : Platform.operatingSystem;
      final appConfig = Get.find<ConfigService>();
      final currentVersion = appConfig.version;

      for (var log in logs) {
        log['url'] = body["downloads"][system.upperFirst]["url"];
        final ul = UpdateLog.fromJson(log);
        final platform = ul.platform.toLowerCase();
        if ((platform != system && platform != 'all') || ul.version <= currentVersion) {
          continue;
        }
        updateLogs.add(ul);
      }
      updateLogs.sort((a, b) => b.version - a.version);
      return updateLogs;
    } catch (e) {
      final errorMsg = "检查update log的过程中出现异常\n错误: $e";
      Log.error(tag, errorMsg);
      throw FetchUpdateLogsException(errorMsg);
    }
  }

  static Future<bool> showUpdateInfo({
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
    final logs = await fetchUpdateLogs();
    if (logs.isEmpty) {
      return false;
    }
    final latestVersionCode = logs.first.version.code;
    final appConfig = Get.find<ConfigService>();
    if (latestVersionCode == appConfig.ignoreUpdateVersion && !forceCheck) {
      return false;
    }
    String content = "";
    String latestVersion = "";
    for (var log in logs) {
      final version = log.version;
      if (latestVersion == "") {
        latestVersion = "ClipShare-${version.name}_${version.code}";
      }
      content += "🏷️$version\n";
      content += "${log.desc}\n\n";
    }
    List<String> pkgTypes = _installerTypes[defaultTargetPlatform] ?? [];
    Widget? customWidget;
    final selectedType = Rx<String?>(null);
    if (pkgTypes.isNotEmpty) {
      selectedType.value = pkgTypes[0];
      final theme = Theme.of(Get.context!);
      const widthBox = SizedBox(width: 5);
      customWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: 8.insetB,
            child: Text(
              TranslationKey.selectInstallerType.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pkgTypes
                    .map((pkgType) {
                      return SingleGroupChip(
                        text: pkgType,
                        isSelected: pkgType == selectedType.value,
                        onTap: () {
                          selectedType.value = pkgType;
                        },
                      );
                    })
                    .cast<Widget>()
                    .separateWith(widthBox)
                    .toList(),
              ),
            );
          }),
          Obx(() {
            return Visibility(
              visible: selectedType.value == ".zip",
              child: Container(
                margin: 5.insetT,
                child: Text(
                  TranslationKey.updateFromZipTips.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }
    var downloadUrl = logs.first.downloadUrl;
    Global.showTipsDialog(
      context: Get.context!,
      title: TranslationKey.newVersionDialogTitle.tr,
      text: content,
      showCancel: true,
      showNeutral: true,
      maxWidth: 300,
      neutralText: TranslationKey.newVersionDialogSkipText.tr,
      cancelText: TranslationKey.dialogCancelText.tr,
      customWidget: customWidget,
      onNeutral: () {
        //写入数据库跳过更新的版本号
        appConfig.setIgnoreUpdateVersion(latestVersionCode);
      },
      okText: TranslationKey.newVersionDialogOkText.tr,
      onOk: () async {
        try {
          if (selectedType.value != null) {
            downloadUrl = _replaceUrlExtension(downloadUrl, selectedType.value!);
          }
          var fileName = Uri.parse(downloadUrl).path.replaceAll("\\", "/").split("/").last;
          var downPath = "";

          if (Platform.isAndroid) {
            //根据架构确定下载的安装包
            if (_currentArch == _archArm32) {
              downloadUrl = downloadUrl.replaceFirst("arm64-v8a", "armeabi-v7a");
              fileName = fileName.replaceFirst("arm64-v8a", "armeabi-v7a");
            } else if (_currentArch == _archX64) {
              downloadUrl = downloadUrl.replaceFirst("arm64-v8a", "x86_64");
              fileName = fileName.replaceFirst("arm64-v8a", "x86_64");
            }
            fileName = "${latestVersion}_$fileName";
          }
          downPath = "${await Constants.updateDownloadFileDirPath}/$fileName";
          await File(downPath).parent.create();
          final openFolderAfterDownload = false.obs;
          Global.showDownloadingDialog(
            context: Get.context!,
            url: downloadUrl,
            filePath: downPath,
            content: Column(
              children: [
                Text(fileName),
                const SizedBox(height: 5),
                Obx(() {
                  return CheckboxListTile(
                    value: openFolderAfterDownload.value,
                    title: Text(TranslationKey.openPathAfterDownload.tr),
                    onChanged: (selected) {
                      openFolderAfterDownload.value = selected ?? false;
                    },
                  );
                }),
              ],
            ),
            onFinished: (success) async {
              if (success) {
                final updateFile = File(downPath);
                if (openFolderAfterDownload.value) {
                  updateFile.openPath();
                } else {
                  if (selectedType.value == ".zip") {
                    _updateWindowsFromZip(updateFile);
                  } else {
                    OpenFile.open(downPath);
                  }
                }
              }
            },
            onError: (error, stack) {
              Global.showTipsDialog(context: Get.context!, text: "error $error,$stack");
            },
          );
        } catch (err, stack) {
          Log.error(tag, "error: $err. $stack");
          downloadUrl.askOpenUrl();
        }
      },
    );
    const notifyKey = "appUpdate";
    final notifyId = await NotifyUtil.notify(
      content: "${TranslationKey.newVersionAvailable.tr} ${logs.first.version}",
      key: notifyKey,
    );
    if (notifyId != null) {
      Future.delayed(2.s, () {
        NotifyUtil.cancel(notifyKey, notifyId);
      });
    }
    return true;
  }

  static String _replaceUrlExtension(String url, String newExtension) {
    assert(newExtension[0] == ".");
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

  static Future<void> _updateWindowsFromZip(File updateFile) async {
    Log.debug(tag, "update zip file downloaded");
    final downDirPath = updateFile.parent.absolute.path;
    final updateFileExtractDirPath = p.join(downDirPath, "temp").normalizePath;
    await Directory(updateFileExtractDirPath).create(recursive: true);
    Log.debug(tag, "zip file extracting");
    //解压zip
    await ZipFile.openAndExtractAsync(updateFile.absolute.path, updateFileExtractDirPath);
    Log.debug(tag, "zip file extracted");
    final execDirPath = File(Platform.resolvedExecutable).parent.absolute.path;
    final batFilePath = p.join(execDirPath, "data", "flutter_assets", "assets", "scripts", "update_windows.bat").normalizePath;
    final process = await Process.start(
      "cmd",
      ['/c', batFilePath, pid.toString(), updateFileExtractDirPath],
      runInShell: true,
      mode: ProcessStartMode.detached,
      workingDirectory: execDirPath,
    );
    Log.debug(tag, 'Update process started (PID: ${process.pid})');
    await Future.delayed(1.s);
    Log.debug(tag, 'Exiting application, waiting for batch update...');
    exit(0);
  }
}
