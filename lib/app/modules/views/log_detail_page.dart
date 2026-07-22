import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/theme/code_editor_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/largeText/large_text.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:re_editor/re_editor.dart';
import 'package:share_plus/share_plus.dart';

class LogDetailPage extends StatefulWidget {
  final String content;
  final File file;

  const LogDetailPage({
    super.key,
    required this.file,
    required this.content,
  });

  @override
  State<StatefulWidget> createState() => _LogDetailState();

}
class _LogDetailState extends State<LogDetailPage>{
  var _findMode = false;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final appConfig = Get.find<ConfigService>();
    final showAppBar = appConfig.isSmallScreen;
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
              icon: const Icon(Icons.search, color: Colors.blueGrey,),
            ),
            if (PlatformExt.isMobile)
              IconButton(
                onPressed: () {
                  Share.shareXFiles([XFile(filePath)], text: TranslationKey.shareFile.tr);
                },
                icon: const Icon(Icons.share, color: Colors.blueGrey,),
              ),
          ],
        )
      ],
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LargeText(
        text: widget.content,
        findMode: _findMode,
        readonly: true,
        codeTheme: CodeHighlightTheme(
          languages: {'log': Constants.codeLogTheme},
          theme: customCodeLightTheme,
        ),
        onFindModeChanged: (opened){
          if(_findMode != opened) {
            setState(() {
              _findMode = opened;
            });
          }
        },
      ),
    );
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: header,
              )
            : null,
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

}
