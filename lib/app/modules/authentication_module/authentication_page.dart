import 'dart:io';

import 'package:clipshare/app/modules/authentication_module/authentication_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AuthenticationPage extends GetView<AuthenticationController> {
  final appConfig = Get.find<ConfigService>();
  final homeController = Get.find<HomeController>();
  final androidChannelService = Get.find<AndroidChannelService>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: controller.backPage.value,
      onPopInvoked: controller.backPage.value
          ? null
          : (bool didPop) {
              if (Platform.isAndroid && appConfig.authenticating.value) {
                androidChannelService.moveToBg();
              }
            },
      child: Scaffold(
        body: SafeArea(
          child: Obx(
            () => AuthPasswordInput(
              onFinished: (String input, String? second) {
                return CryptoUtil.toMD5(input) == appConfig.appPassword;
              },
              onOk: (input) {
                controller.onAuthenticated();
                return false;
              },
              showCancelBtn: controller.backPage.value,
            ),
          ),
        ),
      ),
    );
  }
}
