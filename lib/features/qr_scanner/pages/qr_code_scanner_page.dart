import 'dart:convert';

import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<StatefulWidget> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  static const logTag = 'QRCodeScannerController';
  Barcode? result;
  QRViewController? qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var flashStatus = 'off';
  var cameraFacing = 'back';

  @override
  Widget build(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (context.media.size.width < 400 || context.media.size.height < 400) ? 150.0 : 300.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationKey.qrCodeScannerPageTitle.tr),
      ),
      body: SafeArea(
        child: QRView(
          key: qrKey,
          onQRViewCreated: onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
          onPermissionSet: (ctrl, p) => onPermissionSet(context, p),
        ),
      ),
    );
  }

  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      result = scanData;
      pauseCamera();
      try {
        HapticFeedback.mediumImpact();
        final json = jsonDecode(scanData.code!);
        logger.debug(logTag, scanData.code);
        if (mounted) {
          context.pop(json);
        }
      } catch (err, stack) {
        logger.warn(logTag, '$err $stack');
        if (mounted) {
          dialogManager.tips(
            context,
            autoDismiss: false,
            text: '${TranslationKey.qrCodeScanError.tr}: $err',
            actions: DialogActions(
              confirm: DialogAction(
                onPressed: () {
                  resumeCamera();
                  context.pop();
                },
              ),
            ),
          );
        }
      }
    });
    updateCameraInfo();
  }

  void updateCameraInfo() async {
    final info = await qrController?.getCameraInfo();
    if (info != null) cameraFacing = info.name;
  }

  void toggleFlash() async {
    await qrController?.toggleFlash();
    flashStatus = (await qrController?.getFlashStatus())?.toString() ?? 'off';
  }

  void flipCamera() async {
    await qrController?.flipCamera();
    updateCameraInfo();
  }

  void pauseCamera() => qrController?.pauseCamera();

  void resumeCamera() => qrController?.resumeCamera();

  void onPermissionSet(BuildContext context, bool hasPermission) {
    if (!hasPermission) {
      snackbar.warn(context, 'no Permission');
    }
  }
}
