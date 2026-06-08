import '../forward_presentation.dart';
import 'settings_section_view_base.dart';

class SettingsForwardPage extends SettingsSectionView {
  SettingsForwardPage({super.key, super.embedded}) : super(section: SettingsSection.forward);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.forwardSettingsGroupName.tr,
          icon: const Icon(Icons.cloud_sync_outlined),
          cardList: buildSettingEntries(context),
        ),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
            SettingCard<ForwardWay>(
              searchKeys: const [TranslationKey.forwardWay],
              searchAliases: const ['WebDAV', 'S3'],
              title: Text(TranslationKey.forwardWay.tr),
              value: appConfig.forwardWay,
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
                final v = appConfig.forwardWay;
                final menu = ContextMenu(
                  entries: [
                    MenuItem(
                      label: forwardWayLabel(ForwardWay.server),
                      icon: forwardWayIcon(ForwardWay.server),
                      enabled: v != ForwardWay.server,
                      onSelected: () async {
                        Future<void> setup() async {
                          await appConfig.setForwardWay(ForwardWay.server);
                          await storageService.stop();
                          if (!appConfig.enableForward || appConfig.forwardServer == null) {
                            //若无配置，关闭中转
                            await appConfig.setEnableForward(false);
                            return;
                          }
                          sktService.connectForwardServer(true);
                        }

                        _confirmForwardWayChangeIfNeeded(context, setup);
                      },
                    ),
                    MenuItem(
                      label: forwardWayLabel(ForwardWay.webdav),
                      icon: forwardWayIcon(ForwardWay.webdav),
                      enabled: v != ForwardWay.webdav,
                      onSelected: () {
                        Future<void> setup() async {
                          await appConfig.setForwardWay(ForwardWay.webdav);
                          await sktService.disConnectForwardServer();
                          if (!appConfig.enableForward || appConfig.webDAVConfig == null) {
                            //若无配置，关闭中转
                            await appConfig.setEnableForward(false);
                            return;
                          }
                          storageService.restart();
                        }

                        _confirmForwardWayChangeIfNeeded(context, setup);
                      },
                    ),
                    MenuItem(
                      label: forwardWayLabel(ForwardWay.s3),
                      icon: forwardWayIcon(ForwardWay.s3),
                      enabled: v != ForwardWay.s3,
                      onSelected: () async {
                        Future<void> setup() async {
                          await appConfig.setForwardWay(ForwardWay.s3);
                          await sktService.disConnectForwardServer();
                          if (!appConfig.enableForward || appConfig.s3Config == null) {
                            //若无配置，关闭中转
                            await appConfig.setEnableForward(false);
                            return;
                          }
                          storageService.restart();
                        }

                        _confirmForwardWayChangeIfNeeded(context, setup);
                      },
                    ),
                    MenuItem(
                      label: forwardWayLabel(ForwardWay.none),
                      icon: forwardWayIcon(ForwardWay.none),
                      enabled: v != ForwardWay.none,
                      onSelected: () async {
                        Future<void> setup() async {
                          await appConfig.setEnableForward(false);
                          await appConfig.setForwardWay(ForwardWay.none);
                          await sktService.disConnectForwardServer();
                          await storageService.stop();
                        }

                        _confirmForwardWayChangeIfNeeded(
                          context,
                          setup,
                          confirmWhenCurrentWayNone: true,
                        );
                      },
                    ),
                  ],
                  position: Offset(Get.size.width, details.globalPosition.dy - 50),
                  padding: 8.insetAll,
                  borderRadius: BorderRadius.circular(8),
                );
                menu.show(context);
              },
            ),
            //服务状态/通知服务配置
            if (appConfig.forwardWay != ForwardWay.none)
              SettingCard(
                searchKeys: const [
                  TranslationKey.forwardServerStatus,
                  TranslationKey.notificationServerStatus,
                  TranslationKey.notificationServerConfigure,
                ],
                title: Row(
                  children: [
                    Text(
                      appConfig.forwardWay == ForwardWay.server ? TranslationKey.forwardServerStatus.tr : TranslationKey.notificationServerStatus.tr,
                      maxLines: 1,
                    ),
                    if (appConfig.forwardWay != ForwardWay.server)
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
                          onTap: () async {
                            Global.showTipsDialog(
                              context: context,
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
                      color: controller.forwardServerStatus.value.color,
                    ),
                    const SizedBox(width: 5),
                    Text(controller.forwardServerStatus.value.tr),
                    const SizedBox(width: 5),
                    Obx(() {
                      final status = controller.forwardServerStatus.value;
                      if (status != ForwardServerStatus.connected) {
                        return const SizedBox.shrink();
                      }
                      final version = appConfig.forwardServerVersion.value;
                      if (version.isNullOrEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text("V$version");
                    }),
                  ],
                ),
                value: appConfig.forwardWay == ForwardWay.server,
                action: (isForwardServer) {
                  if (isForwardServer) {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () {
                      Global.showDialog(
                        context,
                        NotificationServerEditDialog(
                          title: TranslationKey.notificationServerConfigure.tr,
                          labelText: TranslationKey.notificationServerAddress.tr,
                          initStr: appConfig.notificationServer,
                          hint: 'ws://',
                          verify: (s) => s.matchRegExp(Constants.wsUrlRegex),
                          errorText: TranslationKey.pleaseInputCorrectWsURL.tr,
                          onOk: (result) {
                            appConfig.setNotificationServer(result.trimEnd('/'));
                            if (appConfig.enableForward) {
                              storageService.reconnectWs();
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
            if (appConfig.forwardWay != ForwardWay.none)
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
                    if (appConfig.forwardWay == ForwardWay.server)
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
                            Constants.forwardDownloadUrl.askOpenUrl();
                          },
                        ),
                      ),
                  ],
                ),
                description: Text(TranslationKey.forwardSettingsForwardDesc.tr),
                value: appConfig.enableForward,
                action: (v) {
                  return Switch(
                    value: v,
                    onChanged: (checked) async {
                      HapticFeedback.mediumImpact();
                      final useServer = appConfig.forwardWay == ForwardWay.server;
                      //启用中转服务器前先校验是否填写服务器地址
                      if (useServer && appConfig.forwardServer == null) {
                        Global.showSnackBarErr(
                          context: context,
                          text: TranslationKey.forwardSettingsForwardEnableRequiredText.tr,
                        );
                        return;
                      }
                      final useWebdav = appConfig.forwardWay == ForwardWay.webdav;
                      if (useWebdav && appConfig.webDAVConfig == null) {
                        Global.showSnackBarErr(
                          context: context,
                          text: TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr,
                        );
                        return;
                      }
                      final useS3 = appConfig.forwardWay == ForwardWay.s3;
                      if (useS3 && appConfig.s3Config == null) {
                        Global.showSnackBarErr(
                          context: context,
                          text: TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr,
                        );
                        return;
                      }
                      await appConfig.setEnableForward(checked);
                      if (checked) {
                        if (useServer) {
                          sktService.connectForwardServer(true);
                        } else {
                          storageService.start();
                        }
                      } else {
                        if (useServer) {
                          sktService.disConnectForwardServer();
                        } else {
                          storageService.stop();
                        }
                      }
                    },
                  );
                },
              ),
            if (appConfig.forwardWay == ForwardWay.server)
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
                value: appConfig.forwardServer,
                action: (v) {
                  String text = TranslationKey.change.tr;
                  if (appConfig.forwardServer == null) {
                    text = TranslationKey.configure.tr;
                  }
                  return Row(
                    children: [
                      if (appConfig.forwardServer != null)
                        IconButton(
                          onPressed: () {
                            Global.showDialog(
                              context,
                              QrImageDialog(
                                title: Text(TranslationKey.forwardServer.tr),
                                data: jsonEncode(appConfig.forwardServer!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                        ),
                      TextButton(
                        onPressed: () {
                          Global.showDialog(
                            context,
                            ForwardServerEditDialog(
                              initValue: v,
                              onOk: (server) {
                                appConfig.setForwardServer(server);
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
            if (appConfig.forwardWay == ForwardWay.webdav)
              SettingCard(
                searchKeys: const [
                  TranslationKey.forwardSettingsWebDAVTitle,
                ],
                searchAliases: const ['WebDAV'],
                title: Text(
                  TranslationKey.forwardSettingsWebDAVTitle.tr,
                  maxLines: 1,
                ),
                description: Text(appConfig.webDAVConfig?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
                value: appConfig.webDAVConfig,
                action: (v) {
                  String text = TranslationKey.change.tr;
                  if (appConfig.webDAVConfig == null) {
                    text = TranslationKey.configure.tr;
                  }
                  return Row(
                    children: [
                      if (appConfig.webDAVConfig != null)
                        IconButton(
                          onPressed: () {
                            Global.showDialog(
                              context,
                              QrImageDialog(
                                title: const Text("WebDAV"),
                                data: jsonEncode(appConfig.webDAVConfig!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                        ),
                      TextButton(
                        onPressed: () {
                          Global.showDialog(
                            context,
                            WebDAVConfigEditDialog(
                              initValue: v,
                              onOk: (config) {
                                appConfig.setWebDavConfig(config);
                                if (appConfig.enableForward) {
                                  storageService.restart();
                                }
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
            if (appConfig.forwardWay == ForwardWay.s3)
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
                description: Text(appConfig.s3Config?.displayName ?? TranslationKey.noConfig.tr, maxLines: 1),
                value: appConfig.s3Config,
                action: (v) {
                  String text = TranslationKey.change.tr;
                  if (appConfig.s3Config == null) {
                    text = TranslationKey.configure.tr;
                  }
                  return Row(
                    children: [
                      if (appConfig.s3Config != null)
                        IconButton(
                          onPressed: () {
                            Global.showDialog(
                              context,
                              QrImageDialog(
                                title: Text(TranslationKey.s3.tr),
                                data: jsonEncode(appConfig.s3Config!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                        ),
                      TextButton(
                        onPressed: () {
                          Global.showDialog(
                            context,
                            S3ConfigEditDialog(
                              initValue: v,
                              onOk: (config) {
                                appConfig.setS3Config(config);
                                if (appConfig.enableForward) {
                                  storageService.restart();
                                }
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
    ];
  }

  /// Confirms relay-mode changes only when an active relay may be interrupted.
  void _confirmForwardWayChangeIfNeeded(
    BuildContext context,
    Future<void> Function() changeForwardWay, {
    bool confirmWhenCurrentWayNone = false,
  }) {
    final shouldConfirm = appConfig.enableForward && (confirmWhenCurrentWayNone || appConfig.forwardWay != ForwardWay.none);
    if (!shouldConfirm) {
      changeForwardWay();
      return;
    }
    Global.showTipsDialog(
      context: context,
      text: TranslationKey.changeForwardWayConfirm.tr,
      showCancel: true,
      onOk: changeForwardWay,
    );
  }
}
