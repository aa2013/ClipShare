import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/extensions/multi_select_dialog_extension.dart';
import 'package:clipshare/core/platform/android/screenshot_detect_provider.dart';
import 'package:clipshare/core/services/backup/backup_provider.dart';
import 'package:clipshare/core/services/backup/backup_source.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/tag/tag_provider.dart';
import 'package:clipshare/core/services/transport/client/storage/storage_client.dart';
import 'package:clipshare/core/services/transport/extensions/storage_config_extension.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/features/settings/widgets/dialog/s3_config_edit_dialog.dart';
import 'package:clipshare/features/settings/widgets/dialog/webdav_config_edit_dialog.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/exceptions/user_cancel_backup_exception.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/radio_group.dart';
import 'package:clipshare/shared/widgets/dialogs/multi_select_dialog.dart';
import 'package:clipshare/shared/widgets/dialogs/single_select_dialog.dart';
import 'package:clipshare/shared/widgets/file_browser.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsBackupPage extends SettingsSectionView {
  const SettingsBackupPage({super.key, super.embedded}) : super(section: SettingsSection.backup);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.backupRestore.tr,
        icon: const Icon(MdiIcons.backupRestore),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.backup,
          TranslationKey.backupSettingDesc,
        ],
        title: Text(TranslationKey.backup.tr),
        description: Text(TranslationKey.backupSettingDesc.tr),
        value: null,
        action: (v) {
          return TextButton(
            onPressed: () => _startBackup(context, ref),
            child: Text(TranslationKey.startUp.tr),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.restore,
          TranslationKey.restoreSettingDesc,
        ],
        title: Text(TranslationKey.restore.tr),
        description: Text(TranslationKey.restoreSettingDesc.tr),
        value: null,
        action: (v) {
          return TextButton(
            onPressed: () => _restore(context, ref),
            child: Text(TranslationKey.selection.tr),
          );
        },
      ),
    ];
  }
}

/// 备份恢复页面交互逻辑
const _tag = 'SettingsBackupPage';

///选择备份恢复项
Future<List<BackupType>> _showBackupTypesDialog(BuildContext context) {
  Completer<List<BackupType>> completer = Completer();
  final types = BackupType.values.where((item) => item != BackupType.version).toList();
  late DialogController dlgController;
  dlgController = showMultiSelectDialog<BackupType>(
    context: context,
    onSelected: (list) {
      completer.complete(list);
    },
    defaultValues: types,
    selections: types.map((item) {
      return CheckboxData(value: item, text: item.tr);
    }).toList(),
    title: Text(TranslationKey.selectBackupItems.tr),
    onCancel: () {
      completer.complete([]);
      dlgController.close();
    },
  );
  return completer.future;
}

///保存 WebDAV 配置并刷新转发设置
Future<bool> _configWebdav(BuildContext context, WidgetRef ref) async {
  final completer = Completer<bool>();
  final configDao = ref.read(appDbProvider).requireValue.configDao;
  final webdavConfig = ref.read(forwardSettingsProvider).requireValue.webdavConfig;
  final dialog = dialogManager.open(
    context,
    WebDAVConfigEditDialog(
      initValue: webdavConfig,
      onOk: (config) async {
        await configDao.addOrUpdate(.webdavConfig, jsonEncode(config));
        ref.invalidate(forwardSettingsProvider);
        completer.complete(true);
      },
    ),
  );
  await dialog.future;
  if (!completer.isCompleted) {
    completer.complete(false);
  }
  return completer.future;
}

///保存 S3 配置并刷新转发设置
Future<bool> _configS3(BuildContext context, WidgetRef ref) async {
  final completer = Completer<bool>();
  final configDao = ref.read(appDbProvider).requireValue.configDao;
  final s3Config = ref.read(forwardSettingsProvider).requireValue.s3Config;
  final dialog = dialogManager.open(
    context,
    S3ConfigEditDialog(
      initValue: s3Config,
      onOk: (config) async {
        await configDao.addOrUpdate(.s3Config, jsonEncode(config));
        ref.invalidate(forwardSettingsProvider);
        completer.complete(true);
      },
    ),
  );
  await dialog.future;
  if (!completer.isCompleted) {
    completer.complete(false);
  }
  return completer.future;
}

///备份来源选项内容：名称、配置描述与编辑入口，配置保存后自动刷新
class _BackupSourceOptionBody extends ConsumerWidget {
  final BackupSource source;

  const _BackupSourceOptionBody({required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurface.withOpacity(0.8),
    );
    final forwardSettings = ref.watch(forwardSettingsProvider).requireValue;
    final isS3 = source == BackupSource.s3;
    final configName = isS3 ? forwardSettings.s3Config?.displayName : forwardSettings.webdavConfig?.displayName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(source.tr),
              Text(
                configName ?? TranslationKey.notConfigured.tr,
                style: textStyle,
              ),
            ],
          ),
        ),
        Visibility(
          visible: configName != null,
          child: Tooltip(
            message: TranslationKey.modify.tr,
            child: IconButton(
              onPressed: () {
                if (isS3) {
                  _configS3(context, ref);
                } else {
                  _configWebdav(context, ref);
                }
              },
              icon: const Icon(
                Icons.edit_note,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

///选择备份恢复来源，本地，s3，webdav
Future<BackupSource?> _showBackupSourceDialog(BuildContext context, WidgetRef ref) {
  Completer<BackupSource?> completer = Completer();
  late DialogController dlgController;
  dlgController = SingleSelectDialog.show<BackupSource>(
    context: context,
    onSelected: (BackupSource source) async {
      if (source == BackupSource.s3 && ref.read(forwardSettingsProvider).requireValue.s3Config == null) {
        //配置s3
        if (!await _configS3(context, ref)) {
          completer.complete(null);
          dlgController.close();
          return;
        }
      }
      if (source == BackupSource.webdav && ref.read(forwardSettingsProvider).requireValue.webdavConfig == null) {
        //配置 webDAV
        if (!context.mounted) {
          completer.complete(null);
          dlgController.close();
          return;
        }
        if (!await _configWebdav(context, ref)) {
          completer.complete(null);
          dlgController.close();
          return;
        }
      }
      completer.complete(source);
    },
    defaultValue: BackupSource.unknown,
    selections: BackupSource.values.where((item) => item != BackupSource.unknown).map((item) {
      return RadioData(
        value: item,
        label: item.tr,
        widget: item == BackupSource.local ? null : _BackupSourceOptionBody(source: item),
      );
    }).toList(),
    title: Text(TranslationKey.selectBackupSource.tr),
    onCancel: () {
      completer.complete(null);
      dlgController.close();
    },
  );
  return completer.future.whenComplete(() => dlgController.close());
}

///备份
Future<void> _startBackup(BuildContext context, WidgetRef ref) async {
  final backupTypes = await _showBackupTypesDialog(context);
  if (!context.mounted) {
    return;
  }
  if (backupTypes.isEmpty) {
    snackbar.warn(context, TranslationKey.userCancelled.tr);
    return;
  }
  final backupSource = await _showBackupSourceDialog(context, ref);
  if (!context.mounted) {
    return;
  }
  if (backupSource == null) {
    snackbar.warn(context, TranslationKey.userCancelled.tr);
    return;
  }
  //若为存储服务，文件写入临时位置，备份完毕后上传至存储服务
  String? path;
  StorageClient? storageClient;
  if (backupSource == BackupSource.local) {
    final result = await FileUtil.pickWritableDirectory();
    if (!context.mounted) {
      return;
    }
    if (result.isUnwritable) {
      dialogManager.tips(context, text: TranslationKey.unWriteablePathTips.tr);
      return;
    }
    path = result.path;
  } else {
    final forwardSettings = ref.read(forwardSettingsProvider).requireValue;
    path = ref.read(appPathsProvider).requireValue.documentsPath;
    if (backupSource == BackupSource.webdav) {
      storageClient = forwardSettings.webdavConfig?.toClient();
    } else {
      storageClient = forwardSettings.s3Config?.toClient();
    }
    if (storageClient == null) {
      var text = TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr;
      if (backupSource != BackupSource.webdav) {
        text = TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr;
      }
      dialogManager.tips(context, text: text);
      return;
    }
  }
  if (path == null) {
    return;
  }
  final backupNotifier = ref.read(backupProvider.notifier);
  final dialog = dialogManager.loading(
    context,
    dismissible: false,
    showCancel: true,
    loadingText: TranslationKey.exporting.tr,
    onCancel: () {
      backupNotifier.cancel();
      snackbar.success(context, TranslationKey.userCancelled.tr);
    },
  );
  await Future.delayed(200.ms);
  final screenshotDetector = ref.read(screenshotDetectProvider.notifier);
  try {
    //如果启用了截图复制，临时关闭
    screenshotDetector.stopListenScreenshot();
    final result = await backupNotifier.backup(Directory(path), backupTypes);
    dialog.close();
    if (!context.mounted) {
      return;
    }
    if (!result.success) {
      final err = result.exception?.err;
      if (err is UserCancelBackup) {
        snackbar.warn(context, TranslationKey.cancelled.tr);
      } else {
        dialogManager.tips(context, text: TranslationKey.exportFailedAndViewLogs.tr);
      }
    } else {
      //文件备份完毕，若为存储服务，上传，显示上传进度弹窗
      var text = TranslationKey.exportSuccess.tr;
      if (storageClient != null) {
        final loadingController = LoadingProgressController(total: 100);
        final uploadDialog = dialogManager.loading(
          context,
          dismissible: false,
          loadingText: TranslationKey.uploading.tr,
          controller: loadingController,
        );
        final localPath = result.localPath!;
        final backupFileName = File(localPath).fileName;
        final uploadSuccess = await storageClient.uploadFile(
          'backup/$backupFileName',
          localPath,
          onProgress: (count, total) {
            int percentage = (count * 100 / total).toInt();
            loadingController.update(percentage);
          },
        );
        await uploadDialog.close();
        if (!context.mounted) {
          return;
        }
        if (uploadSuccess) {
          File(localPath).delete();
        } else {
          text = TranslationKey.exportFailedAndViewLogs.tr;
        }
      }
      dialogManager.tips(context, text: text);
    }
  } catch (err, stack) {
    logger.error(_tag, '$err,$stack');
    if (!context.mounted) {
      return;
    }
    dialogManager.tips(context, text: TranslationKey.exportFailedAndViewLogs.tr);
  } finally {
    dialog.close();
    //恢复截图复制
    screenshotDetector.startListenScreenshot();
  }
}

///恢复备份
Future<void> _restore(BuildContext context, WidgetRef ref) async {
  final backupTypes = await _showBackupTypesDialog(context);
  if (!context.mounted) {
    return;
  }
  if (backupTypes.isEmpty) {
    snackbar.warn(context, TranslationKey.userCancelled.tr);
    return;
  }
  final backupSource = await _showBackupSourceDialog(context, ref);
  if (!context.mounted) {
    return;
  }
  if (backupSource == null) {
    snackbar.warn(context, TranslationKey.userCancelled.tr);
    return;
  }
  String? localFilePath;
  StorageClient? storageClient;
  //若为存储服务，显示文件列表然后下载到临时目录执行解压，显示下载进度弹窗
  if (backupSource == BackupSource.local) {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    localFilePath = result.files[0].path!;
  } else {
    final forwardSettings = ref.read(forwardSettingsProvider).requireValue;
    if (backupSource == BackupSource.webdav) {
      storageClient = forwardSettings.webdavConfig?.toClient();
    } else {
      storageClient = forwardSettings.s3Config?.toClient();
    }
    if (storageClient == null) {
      var text = TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr;
      if (backupSource != BackupSource.webdav) {
        text = TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr;
      }
      dialogManager.tips(context, text: text);
      return;
    }
    late String baseDir;
    if (backupSource == BackupSource.webdav) {
      baseDir = forwardSettings.webdavConfig!.baseDir;
    } else {
      baseDir = forwardSettings.s3Config!.baseDir;
    }
    final initPath = '$baseDir/backup';
    if (!await storageClient.isDirectory('backup')) {
      if (!await storageClient.createDirectory('backup')) {
        if (!context.mounted) {
          return;
        }
        dialogManager.tips(context, text: TranslationKey.createFolder.tr);
        return;
      }
    }
    if (!context.mounted) {
      return;
    }

    FileItem? selectedFile;
    late DialogController fileBrowserDialog;
    fileBrowserDialog = dialogManager.open(
      context,
      SafeArea(
        child: AlertDialog(
          title: Text(TranslationKey.selectStoragePath.tr),
          content: SizedBox(
            width: 350,
            child: FileBrowser(
              onLoadFiles: (String path) async {
                final subPath = path.replaceFirst(baseDir, '').replaceFirst(unixDirSeparate, '');
                final list = await storageClient!.list(path: subPath);
                return list.where((item) => item.isDir || item.name.endsWith('.zip')).map((item) => FileItem(name: item.name, isDirectory: item.isDir, fullPath: item.path)).toList();
              },
              shouldShowUpLevel: (path) => path != baseDir || path.isNullOrEmpty,
              initialPath: initPath,
              onFileClicked: (item) {
                selectedFile = item;
                fileBrowserDialog.close();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => fileBrowserDialog.close(),
              child: Text(TranslationKey.dialogCancelText.tr),
            ),
          ],
        ),
      ),
    );
    await fileBrowserDialog.future;
    if (!context.mounted) {
      return;
    }
    if (selectedFile?.fullPath == null) {
      snackbar.warn(context, TranslationKey.userCancelled.tr);
      return;
    }
    final subPath = selectedFile!.fullPath!.replaceFirst(baseDir, '').replaceFirst(unixDirSeparate, '');
    localFilePath = '${ref.read(appPathsProvider).requireValue.documentsPath}/${selectedFile!.name}'.normalizePath;
    final loadingController = LoadingProgressController();
    final loadingDialog = dialogManager.loading(
      context,
      loadingText: TranslationKey.downloading.tr,
      controller: loadingController,
    );
    final downloadResult = await storageClient.downloadFile(
      subPath,
      localFilePath,
      onProgress: (int count, int total) {
        int percentage = (count * 100 / total).toInt();
        loadingController.update(percentage, 100);
      },
    );
    await loadingDialog.close();
    if (!context.mounted) {
      return;
    }
    if (!downloadResult) {
      dialogManager.tips(context, text: TranslationKey.downloadFailed.tr);
      return;
    }
  }
  if (!context.mounted) {
    return;
  }
  var loadingController = LoadingProgressController();
  final backupNotifier = ref.read(backupProvider.notifier);
  final dialog = dialogManager.loading(
    context,
    dismissible: false,
    showCancel: true,
    loadingText: TranslationKey.importing.tr,
    controller: loadingController,
    onCancel: () {
      backupNotifier.cancel();
    },
  );
  await Future.delayed(200.ms);
  final screenshotDetector = ref.read(screenshotDetectProvider.notifier);
  try {
    //如果启用了截图复制，临时关闭
    screenshotDetector.stopListenScreenshot();
    final exInfo = await backupNotifier.restore(File(localFilePath), loadingController, backupTypes);
    dialog.close();
    if (!context.mounted) {
      return;
    }
    if (exInfo != null) {
      if (backupSource != BackupSource.local) {
        File(localFilePath).delete();
      }
      if (exInfo.err is UserCancelBackup) {
        snackbar.warn(context, TranslationKey.cancelled.tr);
      } else {
        dialogManager.tips(context, title: TranslationKey.importFailed.tr, text: '$exInfo');
      }
    } else {
      dialogManager.tips(context, title: TranslationKey.importSuccess.tr, text: TranslationKey.restoreRestartPrompt.tr);
      //刷新设备、标签与历史记录数据
      ref.invalidate(deviceProvider);
      ref.invalidate(tagProvider);
      ref.read(historiesProvider.notifier).refresh();
    }
  } catch (err, stack) {
    logger.error(_tag, '$err,$stack');
  } finally {
    dialog.close();
    //恢复截图复制
    screenshotDetector.startListenScreenshot();
  }
}
