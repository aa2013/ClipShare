import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AuthenticationController extends GetxController {
  final auth = LocalAuthentication();
  var supportAuth = false;
  var authenticating = false;
  final tag = "AuthenticationPage";
  var backPage = false.obs;
  String? localizedReason;
  final appConfig = Get.find<ConfigService>();
  final homeController = Get.find<HomeController>();
  final androidChannelService = Get.find<AndroidChannelService>();

  @override
  void onInit() {
    super.onInit();
    auth.isDeviceSupported().then((supported) {
      supportAuth = supported;
      if (!supportAuth) {
        return;
      }
      showBottomSheetAuthentication();
    });
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    backPage.value = !args['lock'];
    localizedReason = args['localizedReason'];
  }

  @override
  void onClose() {
    appConfig.authenticating.value = false;
  }

  void showBottomSheetAuthentication() {
    showModalBottomSheet(
      // isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: Get.context!,
      showDragHandle: true,
      isDismissible: false,
      elevation: 100,
      builder: (BuildContext context) {
        authenticate();
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(minWidth: 500),
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    TranslationKey.authenticationPageTitle.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextButton(
                      child: Text(
                        TranslationKey.authenticationPageUsePassword.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      onPressed: () {
                        Future.delayed(100.ms, () {
                          Navigator.pop(context);
                        });
                      },
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: authenticate,
                        child: const Icon(
                          Icons.fingerprint_outlined,
                          color: Colors.blueAccent,
                          size: 100,
                        ),
                      ),
                      TextButton(
                        onPressed: authenticate,
                        child: Text(TranslationKey.authenticationPageStartVerification.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> checkAuth() async {
    if (supportAuth && !authenticating) {
      authenticating = true;
      var authenticated = await auth.authenticate(
        authMessages: [
          AndroidAuthMessages(
            biometricHint: "",
            signInTitle: TranslationKey.authenticationPageRequireAuthentication.tr,
          ),
        ],
        localizedReason: localizedReason ?? TranslationKey.authenticationPageTitle.tr,
      );
      authenticating = false;
      Log.debug(tag, "authenticated $authenticated");
      return authenticated;
    }
    return false;
  }

  void onAuthenticated([bool useSystem = false]) {
    appConfig.authenticating.value = false;
    backPage.value = true;
    homeController.pausedTime = null;
    //正常验证，添加返回值
    Get.back(result: true);
    //调用系统验证，再退一级
    if (useSystem) {
      Get.back(result: true);
    }
  }

  Future<void> authenticate() async {
    checkAuth().then((authenticated) {
      if (authenticated) {
        onAuthenticated(true);
      }
    });
  }
}
