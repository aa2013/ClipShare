import 'package:clipshare/core/constants/network_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:clipshare/core/services/transport/socket/direct/direct_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/features/device/models/qr_device_connection_info.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddDeviceDialog extends ConsumerStatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  ConsumerState<AddDeviceDialog> createState() {
    return _AddDeviceDialogState();
  }
}

class _AddDeviceDialogState extends ConsumerState<AddDeviceDialog> {
  final tag = 'AddDeviceDialog';
  final _ipEditor = TextEditingController();
  final _portEditor = TextEditingController()..text = port.toString();
  final _forwardIdEditor = TextEditingController();
  final _ipErrTxt = TranslationKey.errorFormatIp.tr;
  final _portErrTxt = '0-65535';
  final _forwardIdErrTxt = TranslationKey.pleaseInput.tr;
  var _showIpErr = false;
  var _showPortErr = false;
  var _showForwardIdErr = false;
  var _connecting = false;
  var _connectErr = false;

  DirectNotifier get sktService => ref.read(directProvider.notifier);
  bool forwardMode = false;
  bool forwardConnected = false;

  void attemptConnect(QRDeviceConnectionInfo result) async {
    dialogManager.loading(
      context,
      loadingText: TranslationKey.attemptingToConnect.tr,
    );
    final interfaces = result.interfaces;
    for (var itf in interfaces) {
      for (var address in itf.addresses) {
        logger.debug(tag, 'address $address');
        bool success = await sktService.connect(address);
        if (success) {
          if (mounted) {
            context.pop();
          }
          return;
        }
      }
    }
    //本地连接失败，尝试中转连接
    final forwardHost = ref.read(forwardServerProvider.notifier).forwardServerHost;
    final forwardPort = ref.read(forwardServerProvider.notifier).forwardServerPort;
    if (forwardHost != null && forwardPort != null) {
      bool success = await ref.read(forwardServerProvider.notifier).connectDevice(result.id);
      if (success) {
        if (mounted) {
          context.pop();
        }
        return;
      }
    }
    if (mounted) {
      context.pop();
      await dialogManager.tips(
        context,
        text: TranslationKey.connectFailed.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(TranslationKey.addDeviceDialogTitle.tr),
          Visibility(
            visible: isMobile,
            child: TextButton(
              onPressed: () async {
                var hasPerm = await PermissionHelper.testCameraPerm();
                if (!hasPerm) {
                  await PermissionHelper.reqCameraPerm();
                  hasPerm = await PermissionHelper.testCameraPerm();
                  if (!hasPerm) {
                    if (context.mounted) {
                      await dialogManager.tips(
                        context,
                        text: TranslationKey.noCameraPermission.tr,
                        actions: const .new(confirm: DialogAction(onPressed: openAppSettings)),
                      );
                    }
                    return;
                  }
                }
                if (!context.mounted) {
                  return;
                }
                final json = await context.pushNamed<Map<String, dynamic>>(AppRoutes.qrScanner.name);
                try {
                  if (json != null) {
                    final result = QRDeviceConnectionInfo.fromJson(json);
                    attemptConnect(result);
                  } else {
                    if (context.mounted) {
                      await dialogManager.tips(context, text: TranslationKey.qrCodeScanError.tr);
                    }
                    logger.warn(tag, 'scan result is null');
                  }
                } catch (err, stack) {
                  logger.error(tag, err, stack);
                  if (context.mounted) {
                    await dialogManager.tips(context, text: '$err, $stack');
                  }
                }
              },
              child: Row(
                children: [
                  const Icon(MdiIcons.qrcodeScan, size: 14),
                  const SizedBox(width: 5),
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
                            labelText: 'IP',
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
                  if (!ref.read(forwardServerProvider.notifier).connected) {
                    dialogManager.tips(context, text: TranslationKey.forwardServerNotConnected.tr);
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
          _connectErr ? TranslationKey.connectFailed.tr : '',
          style: const TextStyle(color: Colors.red),
        ),
        IntrinsicWidth(
          child: Row(
            children: [
              TextButton(
                // 连接中禁用取消，等待超时或连接结果
                onPressed: _connecting ? null : () => Navigator.pop(context),
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
                        });
                        if (forwardMode) {
                          if (_forwardIdEditor.text == '') {
                            _showForwardIdErr = true;
                            setState(() {});
                            return;
                          }
                          if (!ref.read(forwardServerProvider.notifier).connected) {
                            dialogManager.tips(context, text: TranslationKey.forwardServerNotConnected.tr);
                            return;
                          }
                        } else {
                          if (!_ipEditor.text.isIPv4 && !_ipEditor.text.isIPv6) {
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
                          //尝试中转连接，失败时保持弹窗并提示
                          final success = await ref.read(forwardServerProvider.notifier).connectDevice(_forwardIdEditor.text);
                          if (!context.mounted) {
                            return;
                          }
                          if (success) {
                            context.pop();
                          } else {
                            setState(() {
                              _connectErr = true;
                              _connecting = false;
                            });
                          }
                        } else {
                          // 直连失败由返回值判定；onErr 只在异常路径触发，不能作为唯一依据
                          final success = await sktService.connect(
                            _ipEditor.text,
                            port: int.parse(_portEditor.text),
                            onErr: (err) => logger.debug(tag, err),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (success) {
                            context.pop();
                          } else {
                            setState(() {
                              _connectErr = true;
                              _connecting = false;
                            });
                          }
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
