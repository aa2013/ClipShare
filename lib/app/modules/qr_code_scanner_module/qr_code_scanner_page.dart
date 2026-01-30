import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/qr_code_scanner_module/qr_code_scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class QRCodeScannerPage extends GetView<QRCodeScannerController> {
  @override
  Widget build(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationKey.qrCodeScannerPageTitle.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: QRView(
          key: controller.qrKey,
          onQRViewCreated: controller.onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
          onPermissionSet: (ctrl, p) => controller.onPermissionSet(context, p),
        ),
      ),
    );
  }
}
