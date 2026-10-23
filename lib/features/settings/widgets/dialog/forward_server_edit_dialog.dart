import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:clipshare/core/services/transport/client/socket/forward_socket_client.dart';
import 'package:clipshare/core/services/transport/enums/forward_msg_type.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/settings/forward/forward_server_config.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForwardServerEditDialog extends ConsumerStatefulWidget {
  final void Function(ForwardServerConfig serverConfig) onOk;
  final ForwardServerConfig? initValue;

  const ForwardServerEditDialog({
    super.key,
    this.initValue,
    required this.onOk,
  });

  @override
  ConsumerState<ForwardServerEditDialog> createState() => _ForwardServerEditDialogState();
}

class _ForwardServerEditDialogState extends ConsumerState<ForwardServerEditDialog> {
  final tag = 'ForwardServerEditDialog';
  final hostEditor = TextEditingController();
  final portEditor = TextEditingController();
  final keyEditor = TextEditingController();
  String? hostErrText;
  String? portErrText;
  String? keyErrText;
  bool useKey = false;
  bool detecting = false;
  String serverVersion = '';

  @override
  void initState() {
    super.initState();
    if (widget.initValue == null) return;
    reset(widget.initValue!);
  }

  void reset(ForwardServerConfig config) {
    hostEditor.text = config.host;
    portEditor.text = config.port.toString();
    if (config.key != null) {
      keyEditor.text = config.key!;
      useKey = true;
    }
  }

  bool checkHostEditor() {
    hostErrText = !hostEditor.text.isDomain && !hostEditor.text.isIPv4 && !hostEditor.text.isIPv6 ? TranslationKey.pleaseInputValidDomainOrIpv4_6.tr : null;
    return hostErrText == null;
  }

  bool checkPortEditor() {
    portErrText = !portEditor.text.isPort ? TranslationKey.pleaseInputValidPort.tr : null;
    return portErrText == null;
  }

  bool checkKeyEditor() {
    if (useKey == false) return true;
    keyErrText = keyEditor.text == '' ? TranslationKey.pleaseInputKey.tr : null;
    return keyErrText == null;
  }

  bool checkIsValid() {
    var isValid = checkHostEditor();
    isValid &= checkPortEditor();
    isValid &= checkKeyEditor();
    setState(() {});
    return isValid;
  }

  void checkConn() {
    if (detecting || !checkIsValid()) {
      return;
    }
    setState(() {
      detecting = true;
      serverVersion = '';
    });
    final forwardServer = ref.read(forwardServerProvider.notifier);
    ForwardSocketClient.connect(
      ip: hostEditor.text,
      port: portEditor.text.toInt(),
      onConnected: (client) {
        final data = forwardServer.forwardClientBaseMsg
          ..addAll({
            'connType': ForwardConnType.check.name,
          });
        if (useKey) {
          data['key'] = keyEditor.text;
        }
        client.send(data);
      },
      onDone: (client) {
        if (mounted) {
          setState(() {
            detecting = false;
          });
        }
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        if (json.containsKey('version')) {
          if (mounted) {
            setState(() {
              serverVersion = json['version']?.toString() ?? '';
            });
          }
        }
        if (!json.containsKey('result')) {
          if (mounted) {
            dialogManager.tips(
              context,
              text: data,
              title: TranslationKey.forwardServerUnknownResult.tr,
            );
          }
        } else {
          String result = json['result'];
          if (result != 'success') {
            if (mounted) {
              dialogManager.tips(
                context,
                text: result,
                title: TranslationKey.connectFailed.tr,
              );
            }
          } else {
            String content = '';
            if (json.containsKey('unlimited')) {
              content = '${TranslationKey.forwardServerUnlimitedDevices.tr}\n';
            } else {
              if (!json.containsKey('deviceLimit')) {
                content = '${TranslationKey.publicForwardServer.tr}\n';
                if (json.containsKey('fileSyncRate')) {
                  content += "${TranslationKey.forwardServerSyncFileRateLimit.tr}: ${json["fileSyncRate"]} KB/s\n";
                } else if (json.containsKey('fileSyncNotAllowed')) {
                  content += '${TranslationKey.forwardServerCannotSyncFile.tr}\n';
                } else {
                  content += '${TranslationKey.forwardServerNoLimits.tr}\n';
                }
              } else {
                String deviceLimit = json['deviceLimit'];
                if (deviceLimit == '∞') {
                  deviceLimit = TranslationKey.noLimits.tr;
                } else {
                  deviceLimit += ' ${TranslationKey.deviceUnit.tr}';
                }
                String lifeSpan = json['lifeSpan'];
                if (lifeSpan == '∞') {
                  lifeSpan = TranslationKey.noLimits.tr;
                } else {
                  lifeSpan += ' ${TranslationKey.day.tr}';
                }
                String rate = json['rate'];
                if (rate == '∞') {
                  rate = TranslationKey.noLimits.tr;
                } else {
                  rate += ' KB/s';
                }
                String remaining = json['remaining'];
                if (remaining == '-1') {
                  remaining = TranslationKey.forwardServerKeyNotStarted.tr;
                } else if (remaining != '0') {
                  remaining = '${(remaining.toDouble() / (24 * 60 * 60)).toStringAsFixed(2)} 天';
                } else {
                  remaining = TranslationKey.exhausted.tr;
                }
                String remark = json['remark'];
                content =
                    ''
                    '${TranslationKey.forwardServerDeviceConnectionLimit.tr}: $deviceLimit\n'
                    '${TranslationKey.forwardServerLifeSpan.tr}: $lifeSpan\n'
                    '${TranslationKey.forwardServerRemainingTime.tr}: $remaining\n'
                    '${TranslationKey.forwardServerRateLimit.tr}: $rate\n';
                if (remark.isNotEmpty) {
                  content += '${TranslationKey.forwardServerRemark.tr}：\n$remark\n';
                }
              }
            }
            if (mounted) {
              dialogManager.tips(
                context,
                text: content,
                title: TranslationKey.connectSuccess.tr,
              );
            }
          }
        }
        client.close();
      },
      onError: (err, client) {
        logger.error(tag, 'onError $err');
        if (mounted) {
          dialogManager.tips(
            context,
            text: err.toString(),
            title: TranslationKey.connectFailed.tr,
          );
          setState(() {
            detecting = false;
          });
        }
      },
    ).catchError((err) {
      //返回的 Future 结果不会被使用，失败时以 empty 占位满足返回类型
      if (!mounted) {
        return ForwardSocketClient.empty;
      }
      dialogManager.tips(
        context,
        text: (err as SocketException).message,
        title: TranslationKey.connectFailed.tr,
      );
      setState(() {
        detecting = false;
      });
      return ForwardSocketClient.empty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(TranslationKey.configureForwardServerDialogTitle.tr),
          if (isMobile)
            Tooltip(
              message: TranslationKey.scan.tr,
              child: IconButton(
                    onPressed: detecting
                        ? null
                        : () async {
                            var hasPerm = await PermissionHelper.testCameraPerm();
                            if (!hasPerm) {
                              await PermissionHelper.reqCameraPerm();
                              hasPerm = await PermissionHelper.testCameraPerm();
                              if (!hasPerm) {
                                if (!context.mounted) {
                                  return;
                                }
                                await dialogManager.tips(
                                  context,
                                  text: TranslationKey.noCameraPermission.tr,
                                  actions: const DialogActions(
                                    confirm: DialogAction(
                                      onPressed: openAppSettings
                                    )
                                  ),
                                );
                                return;
                              }
                            }
                            if (!context.mounted) {
                              return;
                            }
                            final json = await context.pushNamed<Map<String, dynamic>>(AppRoutes.qrScanner.name);
                            if (!context.mounted) {
                              return;
                            }
                            try {
                              if (json != null) {
                                final result = ForwardServerConfig.fromJson(json);
                                setState(() {
                                  reset(result);
                                });
                              } else {
                                await dialogManager.tips(context, text: TranslationKey.qrCodeScanError.tr);
                                logger.warn(tag, 'scan result is null');
                              }
                            } catch (err, stack) {
                              logger.error(tag, err, stack);
                              if (!context.mounted) {
                                return;
                              }
                              await dialogManager.tips(context, text: TranslationKey.qrCodeScanError.tr);
                            }
                          },
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.blueGrey,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !detecting,
                      controller: hostEditor,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: TranslationKey.domainAndIp.tr,
                        labelText: TranslationKey.host.tr,
                        border: const OutlineInputBorder(),
                        errorText: hostErrText,
                        helperText: '',
                      ),
                      onChanged: (str) {
                        checkHostEditor();
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      enabled: !detecting,
                      controller: portEditor,
                      decoration: InputDecoration(
                        hintText: TranslationKey.port.tr,
                        labelText: TranslationKey.port.tr,
                        border: const OutlineInputBorder(),
                        errorText: portErrText,
                        helperText: '',
                        helperMaxLines: 2,
                      ),
                      onChanged: (str) {
                        checkPortEditor();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  enabled: !detecting,
                  title: Text(TranslationKey.useKey.tr),
                  value: useKey,
                  onChanged: (v) {
                    if (v == false) {
                      keyErrText = null;
                    }
                    setState(() {
                      useKey = v ?? false;
                    });
                  },
                ),
              ),
              Visibility(
                visible: useKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !detecting,
                        keyboardType: TextInputType.multiline,
                        minLines: 3,
                        maxLines: 3,
                        controller: keyEditor,
                        decoration: InputDecoration(
                          hintText: TranslationKey.accessKey.tr,
                          labelText: TranslationKey.pleaseInputAccessKey.tr,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          errorText: keyErrText,
                          helperText: '',
                        ),
                        onChanged: (str) {
                          checkKeyEditor();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (serverVersion.isNotEmpty)
                Padding(
                  padding: 16.insetL,
                  child: Text('V${TranslationKey.version.tr}: $serverVersion'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: !detecting,
              replacement: const Loading(
                width: 20,
              ),
              child: TextButton(
                onPressed: () {
                  checkConn();
                },
                child: Text(TranslationKey.checkConnection.tr),
              ),
            ),
            IntrinsicWidth(
              child: Row(
                children: [
                  TextButton(
                    onPressed: detecting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: detecting
                        ? null
                        : () {
                            if (hostErrText != null || portErrText != null || keyErrText != null) {
                              return;
                            }
                            widget.onOk(
                              ForwardServerConfig(
                                host: hostEditor.text,
                                port: portEditor.text.toInt(),
                                key: useKey ? keyEditor.text : null,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                    child: Text(TranslationKey.dialogConfirmText.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
