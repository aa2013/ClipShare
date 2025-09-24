import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddDeviceDialogState();
  }
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final tag = "AddDeviceDialog";
  final _ipEditor = TextEditingController();
  final _portEditor = TextEditingController()..text = Constants.port.toString();
  final _forwardIdEditor = TextEditingController();
  final _ipErrTxt = TranslationKey.errorFormatIpv4.tr;
  final _portErrTxt = "0-65535";
  final _forwardIdErrTxt = TranslationKey.pleaseInput.tr;
  var _showIpErr = false;
  var _showPortErr = false;
  var _showForwardIdErr = false;
  var _connecting = false;
  var _connectErr = false;
  final sktService = Get.find<SocketService>();
  bool forwardMode = false;
  Map<String, dynamic> _connectData = {};
  bool forwardConnected = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(TranslationKey.addDeviceAppBarTittle.tr),
          Visibility(
            visible: PlatformExt.isMobile,
            child: TextButton(
              onPressed: () async {
                var hasPerm = await PermissionHelper.testAndroidCameraPerm();
                if (!hasPerm) {
                  await PermissionHelper.reqAndroidCameraPerm();
                  hasPerm = await PermissionHelper.testAndroidCameraPerm();
                  if (!hasPerm) {
                    Global.showTipsDialog(
                      context: context,
                      text: TranslationKey.noCameraPermission.tr,
                    );
                    return;
                  }
                }
                Get.offNamed(Routes.QR_CODE_SCANNER);
              },
              child: Row(
                children: [
                  Icon(
                    MdiIcons.qrcodeScan,
                    size: 14,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    TranslationKey.scan.tr,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 250,
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Visibility(
                replacement: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: TextField(
                          autofocus: true,
                          enabled: !_connecting,
                          controller: _ipEditor,
                          decoration: InputDecoration(
                            labelText: "IP",
                            border: const OutlineInputBorder(),
                            errorText: _showIpErr ? _ipErrTxt : null,
                          ),
                          onChanged: (text) {
                            if (_showIpErr) {
                              setState(() {
                                _showIpErr = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: TextField(
                        enabled: !_connecting,
                        controller: _portEditor,
                        decoration: InputDecoration(
                          labelText: TranslationKey.port.tr,
                          errorText: _showPortErr ? _portErrTxt : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (text) {
                          if (_showPortErr) {
                            setState(() {
                              _showPortErr = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                visible: forwardMode,
                child: SizedBox(
                  height: 80,
                  child: TextField(
                    autofocus: true,
                    enabled: !_connecting,
                    controller: _forwardIdEditor,
                    decoration: InputDecoration(
                      labelText: TranslationKey.deviceId.tr,
                      border: const OutlineInputBorder(),
                      errorText: _showForwardIdErr ? _forwardIdErrTxt : null,
                    ),
                    onChanged: (text) {
                      if (_showForwardIdErr) {
                        setState(() {
                          _showForwardIdErr = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              CheckboxListTile(
                value: forwardMode,
                title: Text(TranslationKey.forwardMode.tr),
                onChanged: (checked) {
                  if (!sktService.forwardServerConnected) {
                    Global.showTipsDialog(context: context, text: TranslationKey.forwardServerNotConnected.tr);
                    return;
                  }
                  setState(() {
                    forwardMode = checked ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Text(
          _connectErr ? TranslationKey.connectFailed.tr : "",
          style: const TextStyle(color: Colors.red),
        ),
        IntrinsicWidth(
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (_connecting) {
                    _connectData['stop'] = true;
                    _connecting = false;
                    setState(() {});
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(TranslationKey.dialogCancelText.tr),
              ),
              const SizedBox(
                width: 10,
              ),
              TextButton(
                onPressed: _connecting
                    ? null
                    : () async {
                        // 194512ad29c18d3bdb4f86f30b257
                        setState(() {
                          _connectErr = false;
                          _connectData = {
                            "stop": false,
                            "custom": true,
                          };
                        });
                        if (forwardMode) {
                          if (_forwardIdEditor.text == "") {
                            _showForwardIdErr = true;
                            setState(() {});
                            return;
                          }
                          if (!sktService.forwardServerConnected) {
                            Global.showTipsDialog(context: context, text: TranslationKey.forwardServerNotConnected.tr);
                            return;
                          }
                        } else {
                          if (!_ipEditor.text.isIPv4) {
                            _showIpErr = true;
                          }
                          if (!_portEditor.text.isPort) {
                            _showPortErr = true;
                          }
                          if (_showIpErr || _showPortErr) {
                            setState(() {});
                            return;
                          }
                        }
                        setState(() {
                          _connecting = true;
                        });
                        if (forwardMode) {
                          //尝试中转连接
                          bool success = await sktService.manualConnectByForward(_forwardIdEditor.text);
                          if (success) {
                            Get.back();
                            return;
                          }
                        } else {
                          sktService.manualConnect(
                            _ipEditor.text,
                            port: int.parse(_portEditor.text),
                            onErr: (err) {
                              Log.debug(tag, err);
                              if (_connecting) {
                                setState(() {
                                  _connectErr = true;
                                  _connecting = false;
                                });
                              }
                            },
                            data: _connectData,
                          ).then((val) {
                            if (_connectErr || _connectData['stop']) {
                              return;
                            }
                            Get.back();
                          });
                        }
                      },
                child: _connecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text(TranslationKey.connect.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
