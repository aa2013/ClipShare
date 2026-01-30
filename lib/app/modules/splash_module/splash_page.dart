import 'package:clipshare/app/modules/splash_module/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SplashPage extends GetView<SplashController> {
  @override
  Widget build(BuildContext context) {
    Get.find<SplashController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/logo/logo.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }
}
