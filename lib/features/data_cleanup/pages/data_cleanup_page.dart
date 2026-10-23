import 'package:clipshare/features/data_cleanup/widgets/auto_clean_config_card.dart';
import 'package:clipshare/features/data_cleanup/widgets/data_cleanup_filter_card.dart';
import 'package:flutter/material.dart';

/// 数据清理页面内容：过滤器卡片与自动清理配置卡片。
/// 仅以设置二级页嵌入形式使用；独立路由入口在旧版即为无调用方的死代码，未迁移。
/// 设备列表联动监听在 DataCleanupPageNotifier.build 内维护。
class DataCleanupPage extends StatelessWidget {
  const DataCleanupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataCleanupFilterCard(),
          SizedBox(height: 4),
          AutoCleanConfigCard(),
        ],
      ),
    );
  }
}
