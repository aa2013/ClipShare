import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.initValue == null) return;
    hostEditor.text = widget.initValue!.host;
    portEditor.text = widget.initValue!.port.toString();
    if (widget.initValue!.key != null) {
      keyEditor.text = widget.initValue!.key!;
      useKey = true;
    }
  }

  bool checkHostEditor() {
    hostErrText = !hostEditor.text.isDomain && !hostEditor.text.isIPv4 ? TranslationKey.pleaseInputValidDomainOrIpv4.tr : null;
    return hostErrText == null;
  }

  bool checkPortEditor() {
    portErrText = !portEditor.text.isPort ? TranslationKey.pleaseInputValidPort.tr : null;
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

  void checkConn() {
    if (detecting || !checkIsValid()) {
      return;
    }
    setState(() {
      detecting = true;
    });
    ForwardSocketClient.connect(
      ip: hostEditor.text,
      port: portEditor.text.toInt(),
      onConnected: (client) {
        final data = ForwardSocketClient.baseMsg
          ..addAll({
            "connType": ForwardConnType.check.name,
          });
        if (useKey) {
          data["key"] = keyEditor.text;
        }
        client.send(data);
      },
      onDone: (client) {
        setState(() {
          detecting = false;
        });
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        if (!json.containsKey("result")) {
          Global.showTipsDialog(
            context: context,
            text: data,
            title: TranslationKey.forwardServerUnknownResult.tr,
          );
        } else {
          String result = json['result'];
          if (result != "success") {
            Global.showTipsDialog(
              context: context,
              text: result,
              title: TranslationKey.connectFailed.tr,
            );
          } else {
            if (json.containsKey("unlimited")) {
              Global.showTipsDialog(
                context: context,
                text: TranslationKey.forwardServerUnlimitedDevices.tr,
                title: TranslationKey.connectSuccess.tr,
              );
              return;
            }
            if (!json.containsKey("deviceLimit")) {
              String content = "${TranslationKey.publicForwardServer.tr}\n";
              if (json.containsKey("fileSyncRate")) {
                content += "${TranslationKey.forwardServerSyncFileRateLimit.tr}: ${json["fileSyncRate"]} KB/s";
              } else if (json.containsKey("fileSyncNotAllowed")) {
                content += TranslationKey.forwardServerCannotSyncFile.tr;
              } else {
                content += TranslationKey.forwardServerNoLimits.tr;
              }
              Global.showTipsDialog(
                context: context,
                text: content,
                title: TranslationKey.connectSuccess.tr,
              );
              return;
            }
            String deviceLimit = json["deviceLimit"];
            if (deviceLimit == "∞") {
              deviceLimit = TranslationKey.noLimits.tr;
            } else {
              deviceLimit += " ${TranslationKey.deviceUnit.tr}";
            }
            String lifeSpan = json["lifeSpan"];
            if (lifeSpan == "∞") {
              lifeSpan = TranslationKey.noLimits.tr;
            } else {
              lifeSpan += " ${TranslationKey.day.tr}";
            }
            String rate = json["rate"];
            if (rate == "∞") {
              rate = TranslationKey.noLimits.tr;
            } else {
              rate += " KB/s";
            }
            String remaining = json["remaining"];
            if (remaining == "-1") {
              remaining = TranslationKey.forwardServerKeyNotStarted.tr;
            } else if (remaining != "0") {
              remaining = "${(remaining.toDouble() / (24 * 60 * 60)).toStringAsFixed(2)} 天";
            } else {
              remaining = TranslationKey.exhausted.tr;
            }
            String remark = json["remark"];
            String content = ""
                "${TranslationKey.forwardServerDeviceConnectionLimit.tr}: $deviceLimit\n"
                "${TranslationKey.forwardServerLifeSpan.tr}: $lifeSpan\n"
                "${TranslationKey.forwardServerRemainingTime.tr}: $remaining\n"
                "${TranslationKey.forwardServerRateLimit.tr}: $rate\n";
            if (remark.isNotEmpty) {
              content += "${TranslationKey.forwardServerRemark.tr}：\n$remark\n";
            }
            Global.showTipsDialog(
              context: context,
              text: content,
              title: TranslationKey.connectSuccess.tr,
            );
          }
        }
        client.destroy();
      },
      onError: (err, client) {
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
    ).catchError((err) {
      Global.showTipsDialog(
        context: context,
        text: (err as SocketException).message,
        title: TranslationKey.connectFailed.tr,
      );
      setState(() {
        detecting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationKey.configureForwardServerDialogTitle.tr),
      content: SizedBox(
        width: 350,
        child: IntrinsicHeight(
          child: Column(
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
                  const SizedBox(
                    width: 4,
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      enabled: !detecting,
                      controller: portEditor,
                      decoration: InputDecoration(hintText: TranslationKey.port.tr, labelText: TranslationKey.port.tr, border: const OutlineInputBorder(), errorText: portErrText, helperText: "", helperMaxLines: 2),
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
                child: Text(TranslationKey.forwardServerConnCheck.tr),
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
