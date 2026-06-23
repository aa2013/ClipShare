import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/widgets/clip/clip_data_copy_icon_button.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/qr_device_connection_info.dart';

class NetworkAddressDialog extends StatelessWidget {
  final List<NetworkInterface> interfaces;

  const NetworkAddressDialog({super.key, required this.interfaces});

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final theme = Theme.of(context);
    final dialogBackground = theme.brightness == Brightness.dark ? theme.dialogTheme.backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface : null;
    final displayInterfaces = interfaces
        .where(
          (interfaceItem) => interfaceItem.addresses.any(
            (address) => address.type == InternetAddressType.IPv4,
          ),
        )
        .toList();
    if (displayInterfaces.isEmpty) {
      return AlertDialog(
        backgroundColor: dialogBackground,
        title: Text(TranslationKey.localIpAddress.tr),
        content: SizedBox(
          width: 280,
          height: 180,
          child: Center(
            child: EmptyContent(size: 80),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(TranslationKey.dialogConfirmText.tr),
              ),
            ],
          ),
        ],
      );
    }
    final qrInterfaces = <DeviceInterfaceInfo>[];
    final qrContent = QRDeviceConnectionInfo(
      id: appConfig.device.guid,
      interfaces: qrInterfaces,
    );
    final widgets = List<Widget>.empty(growable: true);
    for (var interface in displayInterfaces) {
      final addresses = interface.addresses.where((itf) => itf.type == InternetAddressType.IPv4);
      qrInterfaces.add(
        DeviceInterfaceInfo(
          name: interface.name,
          addresses: addresses.map((addr) => addr.address).toList(),
        ),
      );
      widgets.add(renderAddressInfoWidget(interface, addresses));
    }
    return AlertDialog(
      backgroundColor: dialogBackground,
      title: Text(TranslationKey.localIpAddress.tr),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: jsonEncode(qrContent),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.blueGrey,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.blueGrey),
                ),
              ),
            ),
            ...widgets,
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(TranslationKey.dialogConfirmText.tr),
            ),
          ],
        ),
      ],
    );
  }

  Widget renderAddressInfoWidget(NetworkInterface interface, Iterable<InternetAddress> addresses) {
    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          interface.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        ...addresses.map((address) {
          return Row(
            children: [
              CopyIconButton(
                onClick: () {
                  clipboardManager.copy(ClipboardContentType.text, address.address);
                },
              ),
              Expanded(
                child: Tooltip(
                  message: address.address,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(address.address),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
