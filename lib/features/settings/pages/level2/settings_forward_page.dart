import 'dart:async';
import 'dart:convert';

import 'package:clipshare/core/constants/regex_constants.dart';
import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_way.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/features/settings/widgets/dialog/forward_server_edit_dialog.dart';
import 'package:clipshare/features/settings/widgets/dialog/notification_server_edit_dialog.dart';
import 'package:clipshare/features/settings/widgets/dialog/qr_image_dialog.dart';
import 'package:clipshare/features/settings/widgets/dialog/s3_config_edit_dialog.dart';
import 'package:clipshare/features/settings/widgets/dialog/webdav_config_edit_dialog.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/consumer_wrapper.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_section_view_base.dart';

class SettingsForwardPage extends SettingsSectionView {
  const SettingsForwardPage({super.key, super.embedded}) : super(section: SettingsSection.forward);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.forwardSettingsGroupName.tr,
        icon: const Icon(Icons.cloud_sync_outlined),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  /// 判断远端存储的基础目录是否为根路径，根路径允许保存但不能用于中转。
  bool _isRootStorageBaseDir(String baseDir) {
    final normalizedBaseDir = baseDir.trim().unixPath.replaceAll(RegExp(r'/+'), unixDirSeparate);
    return normalizedBaseDir == unixDirSeparate;
  }

  /// 判断指定中转方式当前绑定的远端存储配置是否使用根路径。
  bool _usesRootStorageBaseDir(ForwardSettings settings, ForwardWay way) {
    if (way == .webdav) {
      final config = settings.webdavConfig;
      return config != null && _isRootStorageBaseDir(config.baseDir);
    }
    if (way == .s3) {
      final config = settings.s3Config;
      return config != null && _isRootStorageBaseDir(config.baseDir);
    }
    return false;
  }

  /// 提示用户根路径配置只能保存，不能作为中转工作目录。
  void _showRootPathForwardWarn(BuildContext context) {
    snackbar.warn(
      context,
      TranslationKey.rootPathCannotEnableForward.tr,
    );
  }

  /// 中转已启用时保存根路径配置，需要立即停止存储中转并关闭启用开关。
  Future<void> _disableStorageForwardForRootPath(WidgetRef ref) async {
    final storageService = ref.read(storageProvider.notifier);
    await storageService.stop();
    await _setEnableForward(ref, false);
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final forwardSettings = ref.watch(forwardSettingsProvider).requireValue;
    final storageService = ref.read(storageProvider.notifier);
    final forwardServer = ref.read(forwardServerProvider.notifier);
    final appState = ref.watch(appStateProvider);
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    return [
      SettingCard<ForwardWay>(
        searchKeys: const [TranslationKey.forwardWay],
        searchAliases: const ['WebDAV', 'S3'],
        title: Text(TranslationKey.forwardWay.tr),
        value: forwardSettings.way,
        action: (v) {
          return Tooltip(
            message: TranslationKey.modify.tr,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    forwardWayIcon(v),
                    color: Colors.blueGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    forwardWayLabel(v),
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          );
        },
        onTapDown: (details) {
          final v = forwardSettings.way;
          final menu = ContextMenu(
            entries: [
              MenuItem(
                label: forwardWayLabel(ForwardWay.server),
                icon: forwardWayIcon(ForwardWay.server),
                enabled: v != ForwardWay.server,
                onSelected: () async {
                  Future<void> setup() async {
                    await _setForwardWay(ref, .server);
                    await storageService.stop();
                    if (!forwardSettings.enable || forwardSettings.serverConfig == null) {
                      //若无配置，关闭中转
                      await _setEnableForward(ref, false);
                      return;
                    }
                    unawaited(forwardServer.connectForwardServer(true));
                  }

                  _confirmForwardWayChangeIfNeeded(context, forwardSettings, setup);
                },
              ),
              MenuItem(
                label: forwardWayLabel(ForwardWay.webdav),
                icon: forwardWayIcon(ForwardWay.webdav),
                enabled: v != ForwardWay.webdav,
                onSelected: () {
                  Future<void> setup() async {
                    final shouldDisableForRootPath = forwardSettings.enable
                        && forwardSettings.webdavConfig != null
                        && _usesRootStorageBaseDir(forwardSettings, .webdav);
                    if (shouldDisableForRootPath) {
                      _showRootPathForwardWarn(context);
                    }
                    await _setForwardWay(ref, .webdav);
                    await forwardServer.disConnectForwardServer();
                    if (!forwardSettings.enable || forwardSettings.webdavConfig == null) {
                      //若无配置，关闭中转
                      await _setEnableForward(ref, false);
                      return;
                    }
                    if (shouldDisableForRootPath) {
                      await _disableStorageForwardForRootPath(ref);
                      return;
                    }
                    unawaited(storageService.restart());
                  }

                  _confirmForwardWayChangeIfNeeded(context, forwardSettings, setup);
                },
              ),
              MenuItem(
                label: forwardWayLabel(ForwardWay.s3),
                icon: forwardWayIcon(ForwardWay.s3),
                enabled: v != ForwardWay.s3,
                onSelected: () async {
                  Future<void> setup() async {
                    final shouldDisableForRootPath = forwardSettings.enable
                        && forwardSettings.s3Config != null
                        && _usesRootStorageBaseDir(forwardSettings, .s3);
                    if (shouldDisableForRootPath) {
                      _showRootPathForwardWarn(context);
                    }
                    await _setForwardWay(ref, .s3);
                    await forwardServer.disConnectForwardServer();
                    if (!forwardSettings.enable || forwardSettings.s3Config == null) {
                      //若无配置，关闭中转
                      await _setEnableForward(ref, false);
                      return;
                    }
                    if (shouldDisableForRootPath) {
                      await _disableStorageForwardForRootPath(ref);
                      return;
                    }
                    unawaited(storageService.restart());
                  }

                  _confirmForwardWayChangeIfNeeded(context, forwardSettings, setup);
                },
              ),
              MenuItem(
                label: forwardWayLabel(ForwardWay.none),
                icon: forwardWayIcon(ForwardWay.none),
                enabled: v != ForwardWay.none,
                onSelected: () async {
                  Future<void> setup() async {
                    await _setEnableForward(ref, false);
                    await _setForwardWay(ref, .none);
                    await forwardServer.disConnectForwardServer();
                    await storageService.stop();
                  }

                  _confirmForwardWayChangeIfNeeded(
                    context,
                    forwardSettings,
                    setup,
                    confirmWhenCurrentWayNone: true,
                  );
                },
              ),
            ],
            position: Offset(context.media.size.width, details.globalPosition.dy - 50),
            padding: 8.insetAll,
            borderRadius: BorderRadius.circular(8),
          );
          menu.show(context);
        },
      ),
      //服务状态/通知服务配置
      if (forwardSettings.way != ForwardWay.none)
        SettingCard(
          searchKeys: const [
            TranslationKey.forwardServerStatus,
            TranslationKey.notificationServerStatus,
            TranslationKey.notificationServerConfigure,
          ],
          title: Row(
            children: [
              Text(
                forwardSettings.way == ForwardWay.server ? TranslationKey.forwardServerStatus.tr : TranslationKey.notificationServerStatus.tr,
                maxLines: 1,
              ),
              if (forwardSettings.way != ForwardWay.server)
                Tooltip(
                  message: TranslationKey.tips.tr,
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                        size: 15,
                      ),
                    ),
                    onTap: () {
                      dialogManager.tips(
                        context,
                        text: TranslationKey.notificationServerTips.tr,
                      );
                    },
                  ),
                ),
            ],
          ),
          description: Row(
            children: [
              Dot(
                radius: 6.0,
                color: appState.forwardServerStatus.color,
              ),
              const SizedBox(width: 5),
              Text(appState.forwardServerStatus.tr),
              const SizedBox(width: 5),
              consumerWrapper(_renderForwardVersion),
            ],
          ),
          value: forwardSettings.way == ForwardWay.server,
          action: (isForwardServer) {
            if (isForwardServer) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: () {
                dialogManager.open(
                  context,
                  NotificationServerEditDialog(
                    title: TranslationKey.notificationServerConfigure.tr,
                    labelText: TranslationKey.notificationServerAddress.tr,
                    initStr: forwardSettings.notificationServer,
                    hint: 'ws://',
                    verify: (s) => s.matchRegExp(wsUrlRegex),
                    errorText: TranslationKey.pleaseInputCorrectWsURL.tr,
                    onOk: (result) async {
                      final address = result.trimEnd('/');
                      await configDao.addOrUpdate(.notificationServer, address);
                      ref.invalidate(forwardServerProvider);
                      if (forwardSettings.enable) {
                        unawaited(storageService.reconnectWs());
                      }
                    },
                  ),
                );
              },
              child: Text(TranslationKey.configure.tr),
            );
          },
        ),
      //是否启用中转服务
      if (forwardSettings.way != ForwardWay.none)
        SettingCard(
          searchKeys: const [
            TranslationKey.forwardSettingsForwardTitle,
            TranslationKey.forwardSettingsForwardDesc,
          ],
          title: Row(
            children: [
              Text(
                TranslationKey.forwardSettingsForwardTitle.tr,
                maxLines: 1,
              ),
              const SizedBox(width: 5),
              if (forwardSettings.way == ForwardWay.server)
                Tooltip(
                  message: TranslationKey.forwardSettingsForwardDownloadTooltip.tr,
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                        size: 15,
                      ),
                    ),
                    onTap: () async {
                      forwardDownloadUrl.askOpenUrl(context);
                    },
                  ),
                ),
            ],
          ),
          description: Text(TranslationKey.forwardSettingsForwardDesc.tr),
          value: forwardSettings.enable,
          action: (v) {
            return Switch(
              value: v,
              onChanged: (checked) async {
                await HapticFeedback.mediumImpact();
                if (!context.mounted) {
                  return;
                }
                final useServer = forwardSettings.way == ForwardWay.server;
                //启用中转服务器前先校验是否填写服务器地址
                if (useServer && forwardSettings.serverConfig == null) {
                  snackbar.error(
                    context,
                    TranslationKey.forwardSettingsForwardEnableRequiredText.tr,
                  );
                  return;
                }
                final useWebdav = forwardSettings.way == ForwardWay.webdav;
                if (useWebdav && forwardSettings.webdavConfig == null) {
                  snackbar.error(
                    context,
                    TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr,
                  );
                  return;
                }
                final useS3 = forwardSettings.way == ForwardWay.s3;
                if (useS3 && forwardSettings.s3Config == null) {
                  snackbar.error(
                    context,
                    TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr,
                  );
                  return;
                }
                if (checked && _usesRootStorageBaseDir(forwardSettings, forwardSettings.way)) {
                  _showRootPathForwardWarn(context);
                  return;
                }
                await _setEnableForward(ref, checked);
                if (checked) {
                  if (useServer) {
                    unawaited(forwardServer.connectForwardServer(true));
                  } else {
                    unawaited(storageService.start());
                  }
                } else {
                  if (useServer) {
                    await forwardServer.disConnectForwardServer();
                  } else {
                    storageService.stop();
                  }
                }
              },
            );
          },
        ),
      if (forwardSettings.way == ForwardWay.server)
        SettingCard(
          searchKeys: const [
            TranslationKey.forwardSettingsForwardAddressTitle,
            TranslationKey.forwardSettingsForwardAddressDesc,
            TranslationKey.forwardServer,
          ],
          title: Text(
            TranslationKey.forwardSettingsForwardAddressTitle.tr,
            maxLines: 1,
          ),
          description: Text(TranslationKey.forwardSettingsForwardAddressDesc.tr),
          value: forwardSettings.serverConfig,
          action: (v) {
            String text = TranslationKey.change.tr;
            if (forwardSettings.serverConfig == null) {
              text = TranslationKey.configure.tr;
            }
            return Row(
              children: [
                if (forwardSettings.serverConfig != null)
                  IconButton(
                    onPressed: () {
                      dialogManager.open(
                        context,
                        QrImageDialog(
                          title: Text(TranslationKey.forwardServer.tr),
                          data: jsonEncode(forwardSettings.serverConfig!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                  ),
                TextButton(
                  onPressed: () {
                    dialogManager.open(
                      context,
                      ForwardServerEditDialog(
                        initValue: v,
                        onOk: (server) async {
                          await configDao.addOrUpdate(.forwardServer, server.toString());
                          ref.invalidate(forwardSettingsProvider);
                        },
                      ),
                    );
                  },
                  child: Text(text),
                ),
              ],
            );
          },
        ),
      if (forwardSettings.way == ForwardWay.webdav)
        SettingCard(
          searchKeys: const [
            TranslationKey.forwardSettingsWebDAVTitle,
          ],
          searchAliases: const ['WebDAV'],
          title: Text(
            TranslationKey.forwardSettingsWebDAVTitle.tr,
            maxLines: 1,
          ),
          description: Text(forwardSettings.webdavConfig?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
          value: forwardSettings.webdavConfig,
          action: (v) {
            String text = TranslationKey.change.tr;
            if (forwardSettings.webdavConfig == null) {
              text = TranslationKey.configure.tr;
            }
            return Row(
              children: [
                if (forwardSettings.webdavConfig != null)
                  IconButton(
                    onPressed: () {
                      dialogManager.open(
                        context,
                        QrImageDialog(
                          title: const Text('WebDAV'),
                          data: jsonEncode(forwardSettings.webdavConfig!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                  ),
                TextButton(
                  onPressed: () {
                    dialogManager.open(
                      context,
                      WebDAVConfigEditDialog(
                        initValue: v,
                        onOk: (config) async {
                          final shouldDisableForRootPath = forwardSettings.enable
                              && _isRootStorageBaseDir(config.baseDir);
                          if (shouldDisableForRootPath) {
                            _showRootPathForwardWarn(context);
                          }
                          await configDao.addOrUpdate(.webdavConfig, jsonEncode(config));
                          if (forwardSettings.enable) {
                            if (shouldDisableForRootPath) {
                              await _disableStorageForwardForRootPath(ref);
                            } else {
                              unawaited(storageService.restart());
                            }
                          }
                        },
                      ),
                      dismissible: false,
                    );
                  },
                  child: Text(text),
                ),
              ],
            );
          },
        ),
      if (forwardSettings.way == ForwardWay.s3)
        SettingCard(
          searchKeys: const [
            TranslationKey.forwardSettingsS3Title,
            TranslationKey.s3,
          ],
          searchAliases: const ['S3'],
          title: Text(
            TranslationKey.forwardSettingsS3Title.tr,
            maxLines: 1,
          ),
          description: Text(forwardSettings.s3Config?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
          value: forwardSettings.s3Config,
          action: (v) {
            String text = TranslationKey.change.tr;
            if (forwardSettings.s3Config == null) {
              text = TranslationKey.configure.tr;
            }
            return Row(
              children: [
                if (forwardSettings.s3Config != null)
                  IconButton(
                    onPressed: () {
                      dialogManager.open(
                        context,
                        QrImageDialog(
                          title: Text(TranslationKey.s3.tr),
                          data: jsonEncode(forwardSettings.s3Config!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                  ),
                TextButton(
                  onPressed: () {
                    dialogManager.open(
                      context,
                      S3ConfigEditDialog(
                        initValue: v,
                        onOk: (config) async {
                          final shouldDisableForRootPath = forwardSettings.enable && _isRootStorageBaseDir(config.baseDir);
                          if (shouldDisableForRootPath) {
                            _showRootPathForwardWarn(context);
                          }
                          await configDao.addOrUpdate(.s3Config, jsonEncode(config));
                          if (forwardSettings.enable) {
                            if (shouldDisableForRootPath) {
                              await _disableStorageForwardForRootPath(ref);
                            } else {
                              unawaited(storageService.restart());
                            }
                          }
                        },
                      ),
                      dismissible: false,
                    );
                  },
                  child: Text(text),
                ),
              ],
            );
          },
        ),
    ];
  }

  Widget _renderForwardVersion(BuildContext context,WidgetRef ref){
    final appState = ref.watch(appStateProvider);
    final status = appState.forwardServerStatus;
    if (status != ForwardServerStatus.connected) {
      return const SizedBox.shrink();
    }
    final version = appState.transportServerVersion;
    if (version.isNullOrEmpty) {
      return const SizedBox.shrink();
    }
    return Text('V$version');
  }

  Future<void> _setEnableForward(WidgetRef ref, bool enable) async {
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(.enableForward, enable.toString());
    ref.invalidate(forwardSettingsProvider);
  }

  Future<void> _setForwardWay(WidgetRef ref, ForwardWay way) async {
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(.forwardWay, way.name);
    ref.invalidate(forwardSettingsProvider);
  }

  /// Confirms relay-mode changes only when an active relay may be interrupted.
  void _confirmForwardWayChangeIfNeeded(
    BuildContext context,
    ForwardSettings settings,
    Future<void> Function() changeForwardWay, {
    bool confirmWhenCurrentWayNone = false,
  }) {
    final shouldConfirm = settings.enable && (confirmWhenCurrentWayNone || settings.way != .none);
    if (!shouldConfirm) {
      changeForwardWay();
      return;
    }
    dialogManager.tips(
      context,
      text: TranslationKey.changeForwardWayConfirm.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: changeForwardWay,
        )
      ),
    );
  }
}
