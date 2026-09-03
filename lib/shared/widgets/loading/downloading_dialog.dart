import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'loading.dart';

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
  final tag = 'DownloadDialog';
  bool cancel = false;

  Future _downloadFile(void Function(bool success) onComplete) async {
    try {
      await dio.download(
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
      );
    } catch (err, stack) {
      //todo
      if (!mounted) {
        return;
      }
      context.pop();
      if (!cancel) {
        widget.onError?.call(err, stack);
        error = true;
      }
    } finally {
      if (!error) {
        //todo
        if (mounted) {
          Navigator.of(context).pop();
        }
        onComplete(true);
      }
    }
  }

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
                      //todo
                      Navigator.of(context).pop();
                      try {
                        cancel = true;
                        dio.close(force: true);
                      } catch (err, stack) {
                        logger.error(tag, 'error: $error. $stack');
                      }
                      widget.onCancel?.call();
                    },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: downloading
                        ? null
                        : () {
                            setState(() {
                              downloading = true;
                            });
                            // 开始下载
                            _downloadFile(widget.onFinished);
                          },
                    child: Visibility(
                      replacement: Text(TranslationKey.download.tr),
                      visible: downloading,
                      child: Row(
                        children: [
                          const Loading(width: 16),
                          const SizedBox(width: 10),
                          Text(
                            '$progress%',
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
        ),
      ],
    );
  }
}
