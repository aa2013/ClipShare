import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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

  bool _closing = false;

  /// 只移除下载窗口所属 route，不影响后续覆盖在其上的提示窗口。
  void _closeOwnRoute() {
    if (_closing || !mounted) {
      return;
    }
    _closing = true;
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    if (route == null || !route.isActive) {
      return;
    }
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  void dispose() {
    cancel = true;
    dio.close(force: true);
    super.dispose();
  }

  /// 下载完成仅成功回调一次；取消或异常均不能进入成功安装流程。
  Future<void> _downloadFile(void Function(bool success) onComplete) async {
    try {
      await dio.download(
        widget.url,
        widget.savePath,
        onReceiveProgress: (received, total) {
          if (mounted && !cancel && total > 0) {
            // 计算进度百分比
            final p = (received / total * 100);
            setState(() {
              progress = p.toInt();
            });
          }
        },
      );
    } catch (err, stack) {
      if (!mounted || cancel) {
        return;
      }
      error = true;
      _closeOwnRoute();
      widget.onError?.call(err, stack);
      return;
    }
    if (!mounted || cancel) {
      return;
    }
    // 完成回调同步读取下载选项，随后精确关闭所属窗口。
    onComplete(true);
    _closeOwnRoute();
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
                      cancel = true;
                      _closeOwnRoute();
                      try {
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
