import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/theme_constants.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/features/logs/providers/log_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare/shared/widgets/re-editor/code_editor_theme.dart';
import 'package:clipshare/shared/widgets/re-editor/large_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:share_plus/share_plus.dart';

/// 日志详情页路由参数，go_router 通过 extra 携带目标日志文件。
class LogDetailRouteArgs {
  final File file;

  const LogDetailRouteArgs({required this.file});
}

/// 日志详情页，按需读取日志文件内容并支持查找与分享。
class LogDetailPage extends ConsumerStatefulWidget {
  final File file;

  const LogDetailPage({
    super.key,
    required this.file,
  });

  @override
  ConsumerState<LogDetailPage> createState() => _LogDetailState();
}

class _LogDetailState extends ConsumerState<LogDetailPage> {
  var _findMode = false;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final showAppBar = context.isCompactScreen;
    final fileName = file.fileName;
    final filePath = file.path;
    final header = Row(
      children: [
        const Icon(Icons.text_snippet_outlined),
        const SizedBox(width: 5),
        Expanded(child: Text(fileName)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _findMode = !_findMode;
                });
              },
              icon: const Icon(
                Icons.search,
                color: Colors.blueGrey,
              ),
            ),
            if (isMobile)
              IconButton(
                onPressed: () {
                  Share.shareXFiles([XFile(filePath)], text: TranslationKey.shareFile.tr);
                },
                icon: const Icon(
                  Icons.share,
                  color: Colors.blueGrey,
                ),
              ),
          ],
        ),
      ],
    );
    final content = _buildContent(file);
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: header,
        ),
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: header,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  /// 构建日志正文，异步读取期间展示加载态。
  Widget _buildContent(File file) {
    return ref.watch(logContentProvider(file.path)).when(
          data: (text) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LargeText(
              text: text,
              findMode: _findMode,
              readonly: true,
              codeTheme: CodeHighlightTheme(
                languages: {'log': codeLogTheme},
                theme: customCodeLightTheme,
              ),
              onFindModeChanged: (opened) {
                if (_findMode != opened) {
                  setState(() {
                    _findMode = opened;
                  });
                }
              },
            ),
          ),
          loading: () => const Loading(),
          error: (error, stack) => EmptyContent(description: error.toString()),
        );
  }
}
