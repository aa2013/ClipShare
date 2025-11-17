import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/app_update_info_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';

class CheckUpdateButton extends StatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  State<StatefulWidget> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          loading = true;
        });
        AppUpdateInfoUtil.showUpdateInfo(forceCheck: true)
            .then((hasNewest) {
              if (!hasNewest) {
                Global.showSnackBarSuc(context: context, text: TranslationKey.alreadyNewestAppVersion.tr);
              }
            })
            .catchError((err) {
              Global.showTipsDialog(
                context: context,
                text: err.toString(),
              );
            })
            .whenComplete(() {
              setState(() {
                loading = false;
              });
            });
      },
      child: Visibility(
        replacement: Text(TranslationKey.checkUpdate.tr),
        visible: loading,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.0,
          ),
        ),
      ),
    );
  }
}
