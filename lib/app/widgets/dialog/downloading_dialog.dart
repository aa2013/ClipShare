import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadDialog extends StatefulWidget {
  final String url;
  final String savePath;
  final Widget? title;
  final Widget content;
  final void Function()? onCancel;
  final void Function(dynamic err, dynamic stack)? onError;
  final void Function(bool success) onFinished;

  const DownloadDialog({
    super.key,
    required this.url,
    required this.savePath,
    required this.onFinished,
    this.onCancel,
    this.onError,
    this.title,
    required this.content,
  });

  @override
  State<StatefulWidget> createState() {
    return _DownloadDialogState();
  }
}

class _DownloadDialogState extends State<DownloadDialog> {
  bool downloading = false;
  int progress = 0;
  bool error = false;
  final dio = Dio();
  final tag = "DownloadDialog";
  bool cancel = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title ?? Text(downloading ? TranslationKey.downloading.tr : TranslationKey.download.tr),
      content: IntrinsicHeight(child: widget.content),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IntrinsicWidth(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      try {
                        cancel = true;
                        dio.close(force: true);
                      } catch (err, stack) {
                        Log.error(tag, "error: $error. $stack");
                      }
                      widget.onCancel?.call();
                    },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: downloading
                        ? null
                        : () async {
                            setState(() {
                              downloading = true;
                            });
                            // 开始下载
                            dio.download(
                              widget.url,
                              widget.savePath,
                              onReceiveProgress: (received, total) {
                                if (total != -1) {
                                  // 计算进度百分比
                                  final p = (received / total * 100);
                                  setState(() {
                                    progress = p.toInt();
                                  });
                                }
                              },
                            ).catchError((err, stack) {
                              Get.back();
                              if (!cancel) {
                                widget.onError?.call(err, stack);
                                error = true;
                              }
                            }).whenComplete(() {
                              if (!error) {
                                Get.back();
                                widget.onFinished(true);
                              }
                            });
                          },
                    child: Visibility(
                      replacement: Text(TranslationKey.download.tr),
                      visible: downloading,
                      child: Row(
                        children: [
                          const Loading(width: 16),
                          const SizedBox(width: 10),
                          Text(
                            "$progress%",
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}
