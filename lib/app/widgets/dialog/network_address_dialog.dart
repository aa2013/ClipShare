import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/qr_device_connection_info.dart';

class NetworkAddressDialog extends StatelessWidget {
  List<NetworkInterface> interfaces;

  NetworkAddressDialog({super.key, required this.interfaces});

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final qrInterfaces = <DeviceInterfaceInfo>[];
    final qrContent = QRDeviceConnectionInfo(
      id: appConfig.device.guid,
      interfaces: qrInterfaces,
    );
    return AlertDialog(
      title: Text(TranslationKey.localIpAddress.tr),
      content: SingleChildScrollView(
        child: ListBody(
          children: interfaces.map<Widget>((interface) {
            final addresses = interface.addresses
                .where((itf) => itf.type == InternetAddressType.IPv4);
            if (addresses.isEmpty) {
              return const SizedBox.shrink();
            }
            qrInterfaces.add(
              DeviceInterfaceInfo(
                name: interface.name,
                addresses: addresses.map((addr) => addr.address).toList(),
              ),
            );
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
                  return Text(address.address);
                }),
              ],
            );
          }).toList()
            ..insert(
              0,
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: jsonEncode(qrContent),
                    version: QrVersions.auto,
                    gapless: false,
                  ),
                ),
              ),
            ),
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
}
