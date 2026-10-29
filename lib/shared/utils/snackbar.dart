import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';

class SnackbarManager {
  const SnackbarManager._();

  void custom(
    BuildContext context,
    String text,
    Color color,
  ) {
    final snackbar = AnimatedSnackBar(
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
    );
    snackbar.show(context);
  }

  void success(BuildContext context, String text) {
    custom(context, text, Colors.blue.shade700);
  }

  void error(BuildContext context, String text) {
    custom(context, text, Colors.redAccent);
  }

  void warn(BuildContext context, String text) {
    custom(context, text, Colors.orange);
  }
}

const snackbar = SnackbarManager._();
