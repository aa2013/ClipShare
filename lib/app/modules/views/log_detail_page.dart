import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/widgets/largeText/large_text.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogDetailPage extends StatelessWidget {
  final String content;
  final String fileName;

  const LogDetailPage({
    super.key,
    required this.fileName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final appConfig = Get.find<ConfigService>();
    final showAppBar = appConfig.isSmallScreen;
    final header = Row(
      children: [
        const Icon(Icons.text_snippet_outlined),
        const SizedBox(width: 5),
        Text(fileName),
      ],
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LargeText(text: this.content, readonly: true),
    );
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: header,
                backgroundColor: currentTheme.colorScheme.inversePrimary,
              )
            : null,
        body: content,
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
