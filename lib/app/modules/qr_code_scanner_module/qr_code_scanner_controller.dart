import 'dart:convert';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/qr_device_connection_info.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class QRCodeScannerController extends GetxController {
  static const logTag = "QRCodeScannerController";
  final result = Rx<Barcode?>(null);
  QRViewController? qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final flashStatus = 'off'.obs;
  final cameraFacing = 'back'.obs;

  @override
  void onClose() {
    qrController?.dispose();
    super.onClose();
  }

  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      result.value = scanData;
      pauseCamera();
      try {
        HapticFeedback.mediumImpact();
        final json = jsonDecode(scanData.code!);
        Log.debug(logTag, scanData.code);
        final result = QRDeviceConnectionInfo.fromJson(json);
        Get.back();
        attemptConnect(result);
      } catch (err, stack) {
        Log.warn(logTag, "$err $stack");
        Global.showTipsDialog(
          context: Get.context!,
          autoDismiss: false,
          text: "${TranslationKey.qrCodeScanError.tr}: $err",
          onOk: () {
            resumeCamera();
            Get.back();
          },
        );
      }
    });
    updateCameraInfo();
  }

  void updateCameraInfo() async {
    final info = await qrController?.getCameraInfo();
    if (info != null) cameraFacing.value = describeEnum(info);
  }

  void toggleFlash() async {
    await qrController?.toggleFlash();
    flashStatus.value =
        (await qrController?.getFlashStatus())?.toString() ?? 'off';
  }

  void flipCamera() async {
    await qrController?.flipCamera();
    updateCameraInfo();
  }

  void pauseCamera() => qrController?.pauseCamera();

  void resumeCamera() => qrController?.resumeCamera();

  void onPermissionSet(BuildContext context, bool p) {
    if (!p) Get.snackbar('Permission', 'no Permission');
  }

  void attemptConnect(QRDeviceConnectionInfo result) async {
    Global.showLoadingDialog(
      context: Get.context!,
      loadingText: TranslationKey.attemptingToConnect.tr,
    );
    final socketService = Get.find<SocketService>();
    final interfaces = result.interfaces;
    for (var itf in interfaces) {
      for (var address in itf.addresses) {
        bool success = await socketService.manualConnect(address);
        if (success) {
          Get.back();
          return;
        }
      }
    }
    //本地连接失败，尝试中转连接
    final forwardHost = socketService.forwardServerHost;
    final forwardPort = socketService.forwardServerPort;
    if (forwardHost != null && forwardPort != null) {
      bool success = await socketService.manualConnectByForward(result.id);
      if (success) {
        Get.back();
        return;
      }
    }
    Get.back();
    Global.showTipsDialog(
      context: Get.context!,
      text: TranslationKey.connectFailed.tr,
    );
  }
}
