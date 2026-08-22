import 'package:flutter/material.dart';

/// 主控制台页面，作为启动初始化完成后的首个稳定落点。
class MainConsolePage extends StatelessWidget {
  /// 创建主控制台页面。
  const MainConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Main console'),
        ),
      ),
    );
  }
}
