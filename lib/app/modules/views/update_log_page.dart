import 'dart:io';

import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateLogPage extends StatelessWidget {
  const UpdateLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: rootBundle.loadString("assets/md/updateLogs-${Platform.operatingSystem.upperFirst}.md"),
      builder: (context, v) {
        return RoundedScaffold(
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "更新日志",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          icon: const Icon(Icons.info_outline),
          child: Markdown(
            data: v.data ?? "读取失败！",
            selectable: true,
            onSelectionChanged: (
              String? text,
              TextSelection selection,
              SelectionChangedCause? cause,
            ) {},
          ),
        );
      },
    );
  }
}
