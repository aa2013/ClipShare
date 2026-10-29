import 'package:clipshare/features/logs/widgets/log_list_view.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 日志列表页，小屏使用 AppBar，大屏嵌入卡片布局。
class LogPage extends ConsumerWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAppBar = context.isCompactScreen;
    final content = LogListView(
      showHeader: !showAppBar,
    );
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(TranslationKey.logPageAppBarTitle.tr),
              const LogClearButton(),
            ],
          ),
        ),
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }
}
