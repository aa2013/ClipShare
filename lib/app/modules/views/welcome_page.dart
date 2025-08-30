import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  TranslationKey.welcome.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32),
                  child: Text(TranslationKey.welcomeContent.tr),
                ),
                TextButton(
                  onPressed: () {
                    Future.delayed(
                      200.ms,
                      () {
                        Get.offNamed(Routes.USER_GUIDE);
                      },
                    );
                  },
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(TranslationKey.startNow.tr),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }
}
