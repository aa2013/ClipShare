import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';

class SnackbarManager {
  const SnackbarManager._();

  void custom(
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    String text,
    Color color,
  ) {
    assert(context != null || scaffoldMessengerState != null);
    if (context != null) {
      AnimatedSnackBar(
        builder: ((context) {
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(125),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: MaterialAnimatedSnackBar(
              messageText: text,
              backgroundColor: color,
              type: AnimatedSnackBarType.info,
            ),
          );
        }),
        desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
        mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        duration: 4.s,
      ).show(context);
    } else {
      final snackbar = SnackBar(
        content: Text(text),
        backgroundColor: color,
      );
      scaffoldMessengerState!.showSnackBar(snackbar);
    }
  }

  void success({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    custom(context, scaffoldMessengerState, text, Colors.blue.shade700);
  }

  void error({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    custom(context, scaffoldMessengerState, text, Colors.redAccent);
  }

  void warn({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    custom(context, scaffoldMessengerState, text, Colors.orange);
  }
}

const snackbar = SnackbarManager._();
