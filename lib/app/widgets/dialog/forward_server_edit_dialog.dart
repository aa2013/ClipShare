import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/end_point.dart';
import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForwardServerEditDialog extends StatefulWidget {
  final void Function(ForwardServerConfig serverConfig) onOk;
  final ForwardServerConfig? initValue;

  const ForwardServerEditDialog({
    super.key,
    this.initValue,
    required this.onOk,
  });

  @override
  State<StatefulWidget> createState() => _ForwardServerEditDialogState();
}

class _ForwardServerEditDialogState extends State<ForwardServerEditDialog> {
  final tag = "ForwardServerEditDialog";
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
    hostErrText =
        !hostEditor.text.isDomain &&
            !hostEditor.text.isIPv4 &&
            !hostEditor.text.isIPv6
        ? TranslationKey.pleaseInputValidDomainOrIpv4_6.tr
        : null;
    return hostErrText == null;
  }

  bool checkPortEditor() {
    portErrText = !portEditor.text.isPort
        ? TranslationKey.pleaseInputValidPort.tr
        : null;
    return portErrText == null;
  }

  bool checkKeyEditor() {
    if (useKey == false) return true;
    keyErrText = keyEditor.text == "" ? TranslationKey.pleaseInputKey.tr : null;
    return keyErrText == null;
  }

  bool checkIsValid() {
    var isValid = checkHostEditor();
    isValid &= checkPortEditor();
    isValid &= checkKeyEditor();
    setState(() {});
    return isValid;
  }

  Future<void> checkConn() async {
    if (detecting || !checkIsValid()) {
      return;
    }
    setState(() {
      detecting = true;
      serverVersion = "";
    });
    try {
      final client = await ForwardSocketClient.connect(
        key: useKey ? keyEditor.text : null,
        endPoint: EndPoint(hostEditor.text, portEditor.text.toInt()),
        onDone: (client) {
          setState(() {
            detecting = false;
          });
        },
        onMessage: (_, _, _) async {},
        onError: (client, err, stack) {
          Log.error(tag, "onError $err");
          Global.showTipsDialog(
            context: context,
            text: err.toString(),
            title: TranslationKey.connectFailed.tr,
          );
          setState(() {
            detecting = false;
          });
        },
      );
      final serverInfo = client.serverInfo;
      if (serverInfo == null || serverInfo.unknown) {
        Global.showTipsDialog(
          context: context,
          text: serverInfo?.originData ?? "",
          title: TranslationKey.forwardServerUnknownResult.tr,
        );
      } else {
        String title = TranslationKey.connectSuccess.tr;
        if (!serverInfo.success) {
          title = TranslationKey.connectFailed.tr;
        }
        Global.showTipsDialog(
          context: context,
          text: serverInfo.toString(),
          title: title,
        );
      }
      await client.close();
    } catch (err, stack) {
      Global.showTipsDialog(
        context: context,
        text: (err as SocketException).message,
        title: TranslationKey.connectFailed.tr,
      );
      setState(() {
        detecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(TranslationKey.configureForwardServerDialogTitle.tr),
          if (PlatformExt.isMobile)
            Tooltip(
              message: TranslationKey.scan.tr,
              child: IconButton(
                onPressed: detecting
                    ? null
                    : () async {
                        var hasPerm =
                            await PermissionHelper.testAndroidCameraPerm();
                        if (!hasPerm) {
                          await PermissionHelper.reqAndroidCameraPerm();
                          hasPerm =
                              await PermissionHelper.testAndroidCameraPerm();
                          if (!hasPerm) {
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.noCameraPermission.tr,
                            );
                            return;
                          }
                        }
                        final json = await Get.toNamed<dynamic>(
                          Routes.QR_CODE_SCANNER,
                        );
                        try {
                          if (json != null) {
                            final result = ForwardServerConfig.fromJson(json);
                            setState(() {
                              reset(result);
                            });
                          } else {
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.qrCodeScanError.tr,
                            );
                            Log.warn(tag, "scan result is null");
                          }
                        } catch (err, stack) {
                          Log.error(tag, err, stack);
                          Global.showTipsDialog(
                            context: context,
                            text: TranslationKey.qrCodeScanError.tr,
                          );
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
                        helperText: "",
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
                        helperText: "",
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
                          helperText: "",
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
                  child: Text("V${TranslationKey.version.tr}: $serverVersion"),
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
                            if (hostErrText != null ||
                                portErrText != null ||
                                keyErrText != null) {
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
