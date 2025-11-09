import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NotificationServerEditDialog extends StatefulWidget {
  final String title;
  final String? okText;
  final String labelText;
  final String initStr;
  final String hint;
  final bool autofocus;
  final bool Function(String)? verify;
  final String? errorText;
  final void Function(String) onOk;

  const NotificationServerEditDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.initStr,
    this.hint = "",
    required this.onOk,
    this.okText,
    this.verify,
    this.errorText,
    this.autofocus = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _NotificationServerEditDialogState();
  }
}

class _NotificationServerEditDialogState extends State<NotificationServerEditDialog> {
  final _editor = TextEditingController();
  bool showErr = false;
  bool testingConnection = false;
  String version = "";

  @override
  void initState() {
    super.initState();

    _editor.text = widget.initStr;
  }

  bool validateFields() {
    if (widget.verify != null) {
      var valid = widget.verify!(_editor.text);
      if (!valid) {
        setState(() {
          showErr = true;
        });
        return false;
      }
      setState(() {
        showErr = false;
      });
    }
    return true;
  }

  Future<void> _testConnection() async {
    if (validateFields()) {
      setState(() {
        testingConnection = true;
      });
      final dio = Dio();
      var httpUrl = _editor.text.toLowerCase().replaceFirst("ws://", "").replaceFirst("wss://", "");
      httpUrl = "http://$httpUrl/checkVersion";
      ExceptionInfo? exception;
      try {
        final resp = await dio.get(httpUrl);
        assert(resp.data is String && (resp.data as String).isNotEmpty);
        setState(() {
          version = resp.data;
        });
      } catch (err, stack) {
        exception = ExceptionInfo(err: err, stackTrace: stack);
      }
      if (!testingConnection) {
        return;
      }
      setState(() {
        testingConnection = false;
        if (exception != null) {
          version = "";
        }
      });
      if (exception != null) {
        Global.showTipsDialog(context: context, text: "${exception.err}, ${exception.stackTrace}", title: TranslationKey.connectFailed.tr);
      } else {
        Global.showTipsDialog(context: context, text: TranslationKey.connectSuccess.tr, title: TranslationKey.connectSuccess.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _editor,
              autofocus: widget.autofocus,
              decoration: InputDecoration(
                enabled: !testingConnection,
                hintText: widget.hint,
                labelText: widget.labelText,
                hintStyle: TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                errorText: showErr ? widget.errorText : null,
              ),
              onChanged: (str) {
                validateFields();
              },
            ),
            const SizedBox(height: 5),
            Visibility(
              visible: version.isNotEmpty,
              child: Text("${TranslationKey.version.tr}: $version"),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Visibility(
              visible: testingConnection,
              replacement: TextButton(
                onPressed: _testConnection,
                child: Text(TranslationKey.checkConnection.tr),
              ),
              child: const Loading(),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: testingConnection
                        ? null
                        : () {
                            if (!validateFields()) {
                              return;
                            }
                            Navigator.of(context).pop();
                            widget.onOk.call(_editor.text);
                          },
                    child: Text(widget.okText ?? TranslationKey.dialogConfirmText.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
